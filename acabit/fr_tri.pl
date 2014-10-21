#!/usr/bin/perl -C

##########DERNIERE MISE A JOUR 27/10/04


######################################################################################
#
# Corrections : Samuel DUFOUR-KOWALSKI 27/10/2003
#
# *gestion des fichiers
# *adaption des formats d'entrée 
# *calcul du nouvel index
# *nouveau calcul du loglike (prise en compte du nouvel index)
# *nouveau format du fichier res.txt
# *generation du fichier XML avec prise en compte du nouvel index
#   + regroupement des adjectifs relationels avec la forme NPN
#   + prise en compte des nouveaux adj relationnels de temp3.txt
#   + detection des prefiques non
#
# Corrections : Samuel DUFOUR-KOWALSKI 27/10/2004
#
# *passage UTF8 
# *déplace expression régulière  dans fr_def.pl
#
#####################################################################################

use utf8;

require ("lib/fr_def.pl");
# Utilisation des derivations morphologiques définies dans le fichier fr_def2.pl 
require ("lib/fr_def2.pl");

my $TIRETS = "---";
my $IDENT = "[0-9]+";

my $nomfichiersortie;

####################################################################################
#       Ouverture des Fichiers 
####################################################################################

#parametre optionnel : nom du fichier de sortie
if(@ARGV<1)
{
    print "Erreur: Pas de fichier de sortie specifie.\n";
    $nomfichiersortie="out.xml";
}
else 
{
    $nomfichiersortie=shift @ARGV;
}
print "Sortie : $nomfichiersortie\n";

open(FIC_XML, "> $nomfichiersortie");


# Création du fichier contenant tous les termes rencontres
open(FIC_TRI, ">REA/tri.txt");

#BD: Nouveau fichier Sortie avec nouveaux index
open(FIC_NIND, ">REA/newindex.txt");

# Création du fichier dans lequel sera écrit le résultat de la recherche de patrons avec les stats
open(FIC_RES, ">REA/res.txt");

#open(FIC_EXP2, ">REA/exp2.txt");

#Fichier avec resume des couples trouves 
#Exemple d'une ligne :
#1 31 9 production économique (96.228/18.389) 3 * production économique (1)
open(FIC_TMP, "REA/temp.txt") || die("fichier non trouve $!"); #ouverture du fichier en lecture  

#Fichier avec toutes les coccurrences classe par nom de tete
#Exemple d'une ligne :
#production économique 3 --- production économique --- SBC ADJ --- production économique --- na --- BASE --- 92 --- 0014602 --- 1 --- 0 
open(FIC_TMP2, "REA/temp2.txt") || die("fichier non trouve $!"); #ouverture du fichier en lecture 


#Fichier avec adjectif relationnel trouvé par regroupement
#Exemple d'une ligne :
#chromatographique 1 ( )
open(FIC_TMP3, "REA/temp3.txt") || die("fichier non trouve $!"); #ouverture du fichier en lecture 
open(FIC_TMP3_BIS, ">REA/temp3_bis.txt"); #ecriture 

#Fichier avec liste des couples Nom/AdjR
open(FIC_REL, "REA/relationnel.txt") || die("fichier non trouve $!"); #ouverture du fichier en lecture  

#Fichier avec liste des inversions Morphologiques
open(FIC_INV, "REA/inversion.txt") || die("fichier non trouve $!"); #ouverture du fichier en lecture  

#Fichier avec liste des suffixes
open(FIC_PREF, "REA/prefixe.txt") || die("fichier non trouve $!"); #ouverture du fichier en lecture  

#Fichier avec liste des ensembles
open(FIC_ENS, "REA/ensemble.txt") || die("fichier non trouve $!"); #ouverture du fichier en lecture  

#Fichier avec liste des ensembles
open(FIC_TIRET, "REA/tiret.txt") || die("fichier non trouve $!"); #ouverture du fichier en lecture  


##############################################################################################
#                    VARIABLES 
##############################################################################################

#Tableaux qui stockent les differentes liens morphologiques
#lien entre identificateurs;
my %relation=();
my %inv_relation=();
my @new_index=();
my %relation_type=();

#Tableau de tableau qui enregistre pour chaque n° d'ident les autres infos
my @Tab_ref ; 

my %tab;          
my %AdjRel;

#Variables de parcours de tableau
my $i=0 ;
my $j=0 ;

my $nombre=0 ; #Frequence totale

#Variables d'enregistrement des liens morphologiques
my $ident1 ;
my $ident2 ;


#tableau des nouvelles frequences
my @tab_nfreq12=();
my @tab_nfreq1=();
my @tab_nfreq2=();

#tableau des loglike
my %tab_loglike=();


############################################################################
# fonction creation_lien
############################################################################
#
# sauvegarde le lien d'equivalence entre deux identifiants
# $_[0]=identificateur 1
# $_[1]=identificateur 2
# $_[2]=type du lien
############################################################################
sub creation_lien
{
    my $ident1=$_[0];
    my $ident2=$_[1];
    my $tylink=$_[2];

    my ($i1, $i2);

    #si egalité, on quitte
    return if($ident1==$ident2);

    #on index sur le plus petit identificateur (pour eviter les boucles)
    if($ident1<$ident2) { $i1=$ident1; $i2=$ident2; } 
    else  { $i2=$ident1; $i1=$ident2; } 

    #retourne si on a deja traité le lien
    return if(exists ($relation_type{$i1}{$i2}));

    if($i1==1396 || $i2==1396)
    { print "$tylink\n"; }

    #si l'identificateur 2 a déja été indexé
    #on recherche où  placer le nouvel index
    if(exists $inv_relation{$i2} )
    {
	#si l'ancien index est plus petit que le nouvel index
	if($inv_relation{$i2}<$i1)
	{
	    #on ajoute $i1 à l'ancien index
	    push @{$relation{$inv_relation{$i2}}}, $i1; 
	    $inv_relation{$i1}=$inv_relation{$i2};
	}
	#si l'ancien index est plus grand que le nouvel index
	else
	{
	    #on indexe l'ancien sur $i1
	    push @{$relation{$i1}}, $inv_relation{$i2}; 
	    $inv_relation{$inv_relation{$i2}}=$i1;
	}
    }
    #l'identificateur 2 n'a pas encore été indexé
    else
    {
	push @{$relation{$i1}}, $i2; 
	$inv_relation{$i2}=$i1;
    }

    #enregistre le type de relation
    $relation_type{$i1}{$i2}=$tylink;
    
}

############################################################################
# fonction parcours des liens morphologiques
############################################################################
#
# retourne la liste des identificateurs équivalents pour l'idenficateurs donné
# $_[0]=identificateur 
#
############################################################################
sub parcours_lien
{
    my $id=$_[0];
    my @res=($id, 1); #on sauvegarde l'identificateur courant sous forme de couple
    my %reshash=();
    my $l;

    my @tmpar=@{$relation{$id}};
    #supprime le lien pour eviter un nouveau parcours
    delete $relation{$id};

    #pour chaque lien, continuer le parcours de maniere recursive
    foreach $l (@tmpar)
    {
	push @res, parcours_lien($l);
    }

    #on copie la liste dans un hashage pour supprimer les doublons
    %reshash=@res;
    return (%reshash);
}

#####################################################################################################
# Fonction calculant le "LogLike" pour un couple i/j                                                #
#####################################################################################################
#  $_[0] : nombre de couples i/j                                                                    #
#  $_[1] : nombre de couples commencant par i mais ne finisant pas par j                            #
#  $_[2] : nombre de couples ne commencant pas par i mais finisant par j                            #
#  $_[3] : nombre de couples ne commencant pas par i et ne finisant pas par j                       #
#  $_[4] : nombre de couples au total                                                               #
#####################################################################################################
sub like 
{ 
    my $a = $_[0];
    my $b = $_[1];
    my $c = $_[2];
    my $d = $_[3];
    my $N = $_[4];

    my $res = 0;

    no integer;

    $res = $res + $a*(log $a) + $d*(log $d)+ $N*(log $N) - ($a+$b)*(log ($a+$b)) - ($a+$c)*(log ($a+$c)) - ($b+$d)*(log ($b+$d)) - ($c+$d)*(log ($c+$d));
    if ($b != 0) {$res += $b*(log $b)}; 		 
    if ($c != 0) {$res += $c*(log $c)};

    # passage pour ne garder que les 3 premieres decimales et pour rajouter 1000 afin de bien trier le fichier par la suite
    $res = ((int ($res * 1000)) / 1000) + 1000;

    use integer;

    return $res; 
}  


#########################################################################
#
#     Programme Principal 
# 
#######################################################################


######################On recupere les liens morphologiques dans les différents fichiers
########################################################################################

print "\nRecupere les liens morphologiques relationnels \n";
foreach (<FIC_REL>) 
{ 
    chomp($_);
    my $machaine = $_;
    if ($machaine =~ /^(\d+) ($MOT) ($MOT) ($TIRETS) (\d+) ($MOT) ($MOT)$/)
    {
	my $ident1 = $1 ;
	my $ident2 = $5 ;
	creation_lien($ident1, $ident2, "REL");
    }
}

print "\nRecupere les liens morphologiques inversion \n";

foreach (<FIC_INV>) 
{ 
    chomp($_);
    my $machaine = $_;
    if ($machaine =~ /^(\d+) ($MOT) ($MOT) ($TIRETS) (\d+) ($MOT) ($MOT)$/)
    {
	my $ident1 = $1 ;
	my $ident2 = $5 ;
	creation_lien($ident1, $ident2, "INV");
    }
}


print "\nRecupere les liens morphologiques prefixe \n";

foreach (<FIC_PREF>) 
{ 
    chomp($_);
    my $machaine = $_;
    if ($machaine =~ /^(\d+) ($MOT) ($MOT) ($TIRETS) (\d+) ($MOT) ($MOT)$/)
    {
	#ident1 : l'ident du couple prefixe
	my $ident1 = $1 ;
	my $ident2 = $5 ;
	creation_lien($ident1, $ident2, "PREF");
    }
}

print "\nRecupere les liens morphologiques Ensemble \n";

foreach (<FIC_ENS>) 
{ 
    chomp($_);
    my $machaine = $_;
    if ($machaine =~ /^(\d+) ($MOT) ($MOT) ($TIRETS) (\d+) ($MOT) ($MOT)$/)
    {
	my $ident1 = $1 ;
	my $ident2 = $5 ;
	creation_lien($ident1, $ident2, "ENS");
    }
}

print "\nRecupere les liens morphologiques de tiret \n";

foreach (<FIC_TIRET>) 
{ 
    chomp($_); 
    my $machaine = $_;
    if ($machaine =~ /^(\d+) ($MOT) ($MOT) ($TIRETS) (\d+) ($MOT) ($MOT)$/)
    {
	my $ident1 = $1 ;
	my $ident2 = $5 ;
	creation_lien($ident1, $ident2, "TIRET");
    }
}

###### on met toutes les lignes du fichier de statistiques dans un tableau ########
###################################################################################

#lecture du fichier temp.txt

print "\nRecupere les infos des statistiques\n";
#Exemple d'une ligne : 
#1er champ : ident

foreach (<FIC_TMP>) 
{ 
    chomp($_);
    my $machaine = $_;
    #Les candidats
    if ($machaine =~ /^(\d+) (\d+) (\d+) (\d+) ($MOT) ($MOT) (\d+) \* ($INFOS)/) #modif format
    {
	my $lemme1=$5;
	my $lemme2=$6;
	my $freql12=$2;
	my $freql1=$3;
	my $freql2=$4;

	#@tableau= ($2, $3, $4, $5, $6, $7, $8, $9) ;
	my @tableau=  ($2, $3, $4, $5, $6, $7, $8); #modif format
	$Tab_ref[$1] = [ @tableau ] ;
    }
    else
    {
	#La derniere ligne contient la frequence totale
	$nombre = $_ ;
    }
}


############## creation du nouvel Index #############################
#####################################################################
print "\nCalcul du nouvel index\n";

my $j=0;
#pour chaque terme
for( $i=0; $i<= $#Tab_ref; $i++ )
{
    my %hashtmp;

    #si le terme est indexé ailleurs, on passe au terme suivant
    next if(exists $inv_relation{$i});

    #on parcours les termes liés
    %hashtmp=parcours_lien($i);
    #on ne garde que les identificateurs de la table de hachage
    @{$new_index[$j]} = (keys %hashtmp );

    #incremente le nouvel index
    $j++;
}

############################ ecriture du nouvel index #####################
###############################################################################
print "\nEcriture du fichier index.txt\n";

for my $i ( 0 .. $#new_index)
{
    print FIC_NIND "$i\t";
    foreach my $id (@{$new_index[$i]})
    {
	print FIC_NIND "$id ";
    }
    print FIC_NIND "\n";

}



###### on affiche le tableau trie du fichier de statistique #########
#####################################################################


print "\nEcriture du fichier res.txt\n";

#pour chaque nouvel index
for $i ( 0 .. $#new_index)
{
    my $newfreq12=0; # frequence lemme1 + lemme2
    my $newfreq1=0; # frequence lemme1
    my $newfreq2=0; # frequence lemme2
    my %lem1_hash=(); # hachage des premiers lemmes 
    my %lem2_hash=(); # hachage des derniers lemmes 
    my ($id, $l);

    #recherche des premiers lemmes et des derniers lemmes
    foreach $id (@{$new_index[$i]})
    {
	$lem1_hash{ $Tab_ref[$id][3] }=$Tab_ref[$id][1]; # freq premier lemme
	$lem2_hash{ $Tab_ref[$id][4] }=$Tab_ref[$id][2]; # freq deuxieme lemme
	$newfreq12+=$Tab_ref[$id][0];  #frequence du terme
    }
    
    #somme des frequences des premiers lemmes
    foreach $l (keys %lem1_hash)
    {
	$newfreq1+=$lem1_hash{$l};
    }
    #somme des frequences des deuxiemes lemmes
    foreach $l (keys %lem2_hash)
    {
	$newfreq2+=$lem2_hash{$l};
    }

    #sauvegarde des frequences
    $tab_nfreq12[$i]=$newfreq12;
    $tab_nfreq1[$i]=$newfreq1;
    $tab_nfreq2[$i]=$newfreq2;

    my $log;
    #calcul du log like
    if(!$newfreq12 || !$newfreq1 || !$newfreq2)
    {
	$log=0;
    }
    else
    {
	$log=like($newfreq12, $newfreq1-$newfreq12, $newfreq2-$newfreq12, 
		  $nombre - $newfreq12 - $newfreq1 - $newfreq2 ,$nombre);
    }
    
    #savegarde dans un tableau
    $tab_loglike{$i}=$log;
}


###################### ecriture du fichier res.txt ##############################

#pour chaque nouvel index
#on affiche dans l'ordre decroissant du log-like
foreach $i ( sort {$tab_loglike{$b} <=> $tab_loglike{$a} } (keys %tab_loglike))
{
    print FIC_RES "$i $tab_loglike{$i} $tab_nfreq12[$i] $tab_nfreq1[$i] $tab_nfreq2[$i]\n";

    #pour chaque ancien index
    foreach my $id (@{$new_index[$i]})
    {
	print FIC_RES "\t$Tab_ref[$id][3] $Tab_ref[$id][4] ($Tab_ref[$id][0]) * $Tab_ref[$id][6] \n";

    }
}

print FIC_RES "\nFrequence totale : ",$nombre;



###### traitements des adjectifs     relationnels ##########
#############################################################


#on lit les fichier temp3.txt 

print "\nRecupere les infos\n";
# sert a compter le nombre d'adjectifs relationnels
my $nadj = 0;

foreach (<FIC_TMP3>) 
{
    $AdjRel{'nb'} = 1;
    chomp($_);
    my $adjligne = $_;
    if ($adjligne =~ /^($MOT) (.*)$/)
    {
	my $adj = $1;
        $AdjRel{$adj}{'iter'} = 1;
        $nadj++;
    }
}

###### construit le tableau pour stocker les infos en fonction du premier et du dernier lemme #############
###########################################################################################################

#on lit le fichier temp2.txt
foreach (<FIC_TMP2>) 
{ 
    chomp($_);
    my $machaine = $_;
    #production économique 3 --- production économique --- SBC ADJ --- production économique --- na --- BASE --- 92 --- 0014602 --- 1 --- 0 
    if($machaine =~ /^($MOT) ($MOT) ($INFOS) --- (.*) --- (.*) --- (.*) --- (.*)$/)
    {
        my $premierLemme = $1;
        my $dernierLemme = $2;
	my $ident = $3;
        my $infos2 = "$4 --- $5 --- $6 --- $7";
	
        if (exists $tab{$premierLemme})
        {
            $tab{$premierLemme}{$dernierLemme}{$ident}[0]++;
        }
        else
        {
            $tab{$premierLemme}{$dernierLemme}{$ident}[0] = 1;
        }

        my $i = $tab{$premierLemme}{$dernierLemme}{$ident}[0]; 
        $tab{$premierLemme}{$dernierLemme}{$ident}[$i] = $infos2;
    }
}



###### on cherche les nouveaux adjectifs relationnels obtenus par coordination ########
#######################################################################################

# tableau1 : les lemmes
# tableau2 : les etiquettes grammaticales
# tableau3 : les adjectifs finissant pas un adjectif relationnel

print "Detection Nouveaux Adjectifs\n";

my $augmente = 1;
my $iteration = 1;

while ($augmente == 1)
{
        $iteration++;
        my $oldnadj =$nadj;

	#pour couple premierLemme dernierLemme
	for my $premierLemme( keys %tab )
	{
	    for  my $dernierLemme ( keys %{ $tab{$premierLemme} } )
	    {
		next if(!(exists $AdjRel{$dernierLemme}));

		#ecriture du fichier exp2.txt
		#print FIC_EXP2 $premierLemme," ",$dernierLemme,"\n";     

		for my  $infos ( keys %{ $tab{$premierLemme}{$dernierLemme} } )
		{
		    my $infos =~ /^($INFOS) ($TIRETS) ($INFOS) ($TIRETS) ($INFOS) ($TIRETS) ($MOT) ($TIRETS) ($MOT)$/;     
		    my $suiteEtiq = $3;
		    my $suiteLem = $5;
		    my $struct = $7;
		    my $type = $9;
		    
		    if ((($struct eq "na") or ($struct eq "npna")) and (($type eq "COORD") or ($type eq "ENUM")))
		    {
			 # stockage de tous les lemmes du patron dans un tableau
			@tableau1 = split(/ /,$suiteLem);
			 # stockage de toutes les etiquettes du patron dans un tableau
			@tableau2 = split(/ /,$suiteEtiq);

			$j = 0;
			@tableau3=();

			#pour chaque etiquette du terme
			for(my $i=0; $i <= $#tableau2; $i++)
			{
			    if ($tableau2[$i] eq $ADJ_ETIQUET)
			    {
				$valide=0;
				$valide=1 if ($iteration == 2);
				
				# BD : Modification tableau suffixe
				for (my $k=0 ; $k < $#tabSufrel ; $k++ )
				{
				    # le suffixe d'adjectif est le premier champ
				    # BD : Modification tableau suffixe
				    $suffixe = $tabSufrel[$k] ;
				    				    
				    # si le dernier lemme finit par ce suffixe
				    if ($tableau1[$i] =~ /(.*)($suffixe)$/)
				    {
					$valide = 1;
				    }
				}
				if ($valide == 1)
				{
				    $tableau3[$j] = $tableau1[$i];
				    $j++;
				}
			    }
			}
			
			#Traitement du tableau comportant les adjectifs relationnels
			
			if ($j>1)
			{
			    for($i=0; $i < @tableau3; $i++)
			    {
				my $PAdj =$tableau3[$i];
				
				if ( !(exists $AdjRel{$PAdj})) { $AdjRel{$PAdj}{'iter'} = $iteration; }
				
				$k=0;
				for($j=0; $j <= $#tableau3; $j++)
				{
				    my $DAdj =$tableau3[$j];
				    if ($j != $i)
				    {
					$AdjRel{$PAdj}{$DAdj} = 1;
					$k++;
				    }
				}
			    }
			}
		    }
		}
	    } # fin for lemme2
	} # fin for lemme1

	#nbr d'adj
	$nadj=(keys %AdjRel);

	#condition d'arrêt
	if ($nadj == $oldnadj) {$augmente = 0;}
	print $nadj," ",$oldnadj,"\n";
}


######## on ecrit la liste des adjectifs relationnels ###########
#################################################################


# Création du fichier dans lequel seront ecrits les adjectifs relationnels

# Affichage de tous les adjectifs relationnels reperes
for my $Adj ( keys %AdjRel )
{
    # Pour tous les elements de "AdjRel" sauf "nb" qui est un compteur
    if ($Adj ne "nb")
    {
	print FIC_TMP3_BIS $Adj," ",$AdjRel{$Adj}{'iter'}," ( ",;

	for $Adj2 ( keys %{ $AdjRel{$Adj} } )
	    {
		if ($Adj2 ne "iter") {print FIC_TMP3_BIS $Adj2," ";}
	    }

	print FIC_TMP3_BIS ")\n";
    }
}


######## on ecrit le fichier contenant tous les termes rencontres #########
###########################################################################


print "\nEcriture des termes rencontres\n";

#fichier tri.txt  (sans nouvel index)
for my $premierLemme( keys %tab )
{
    for my $dernierLemme ( keys %{ $tab{$premierLemme} } )
    {
	print FIC_TRI $premierLemme," ",$dernierLemme," :\n";

	for my  $infos1 ( keys %{ $tab{$premierLemme}{$dernierLemme} } )
	{
	    my $freq = $tab{$premierLemme}{$dernierLemme}{$infos1}[0];

	    print FIC_TRI "* ",$infos1," ",$freq;

	    for (my $pos=1; $pos<$freq+1; $pos++)
	    {
		print FIC_TRI " ( ",$tab{$premierLemme}{$dernierLemme}{$infos1}[$pos]," )";
	    }

	    print FIC_TRI "\n";
	}
    }
}

#####################################################################################
# GENERATION DU FICHIER XML
#
####################################################################################

#########################################
# fonction qui detect si un nouveau candidat 
#  : adjectif relationel est present dans le terme
#  : particule non 
# $_[0]: terme
# return le type de lien en cas de succes, sinon 0
##########################################
sub detect_new_candidat
{
    my $tm=$_[0];
    my @slem=split(/ /, $tm);
    my $l;

     #enleve le premier et le dernier lemme
    pop @slem; shift @slem;
    #pour chaque lemme du terme
    foreach $l (@slem)
    {
	if ($l eq "non")
	{
	    return "Neg";
	}

	if (exists $AdjRel{$l})
	{ 
	    return "Spec"; 
	}
	
    }

    return "";
}

#########################################
# fonction qui remplit un hachage avec les infos d'un terme donné
# $_[0]: identificateur du terme
# $_[1]: reference de la table de hachage
##########################################
sub get_candidat
{
    my $term_id=$_[0];
    my $term_tab_ref=$_[1];

    # on recupere les lemmes
    my $premierLemme=$Tab_ref[$term_id][3];
    my $dernierLemme=$Tab_ref[$term_id][4];
    my $infos1;
    
    #pour chaque terme
    for  $infos1 ( keys %{ $tab{$premierLemme}{$dernierLemme} } )
    {
	my $freqterm = $tab{$premierLemme}{$dernierLemme}{$infos1}[0];
	
	$infos1=~/^($IDENT) ($TIRETS) (.*) ($TIRETS) (.*) ($TIRETS) (.*) ($TIRETS) (.*) ($TIRETS) (.*)/;
	my $literal_term=$3;
	my $morpho_term=$7;
	my $struct=$9; $struct=~ tr/a-z/A-Z/;
	my $type=$11;
	
	#on regroupe les termes identiques
	$term_tab_ref->{$term_id}{$morpho_term}{'freq'}+=$freqterm;
	$term_tab_ref->{$term_id}{$morpho_term}{'struct'}=$struct;
	$term_tab_ref->{$term_id}{$morpho_term}{'type'}=$type;
    }
}

print "\nEcriture du fichier XML\n";

#entete XML
print FIC_XML "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
#print FIC_XML "<!DOCTYPE LISTCAND [\n";
#print FIC_XML "<!ELEMENT LISTCAND (SETCAND*)>\n";
#print FIC_XML "<!ELEMENT SETCAND (LINK*,CAND*)>\n";
#print FIC_XML "<!ELEMENT CAND (NPN*, NA*)>\n";
#print FIC_XML "<!ELEMENT NPN ((MODIF|BASE|COORD)*)>\n";
#print FIC_XML "<!ELEMENT NA ((MODIF|BASE|COORD)*)>\n";
#print FIC_XML "<!ELEMENT BASE (TERM)>\n";
#print FIC_XML "<!ELEMENT COORD (TERM)>\n";
#print FIC_XML "<!ELEMENT MODIF (TERM)>\n";
#print FIC_XML "<!ELEMENT TERM (#PCDATA)>\n";
#print FIC_XML "<!ATTLIST SETCAND new_ident CDATA #IMPLIED>\n";
#print FIC_XML "<!ATTLIST SETCAND loglike CDATA #IMPLIED>\n";
#print FIC_XML "<!ATTLIST SETCAND freq CDATA #IMPLIED>\n";
#print FIC_XML "<!ATTLIST CAND old_ident CDATA #IMPLIED>\n";
#print FIC_XML "<!ATTLIST NPN freq CDATA #IMPLIED>\n";
#print FIC_XML "<!ATTLIST NA freq CDATA #IMPLIED>\n";
#print FIC_XML "<!ATTLIST LINK type CDATA #IMPLIED>\n";
#print FIC_XML "<!ATTLIST LINK old_ident1 CDATA #IMPLIED>\n";
#print FIC_XML "<!ATTLIST LINK old_ident2 CDATA #IMPLIED>\n";
#print FIC_XML "]>\n\n";

print FIC_XML "<LISTCAND>\n";

#pour chaque nouvel identificateur
#on affiche dans l'ordre decroissant du log-like
foreach $i ( sort {$tab_loglike{$b} <=> $tab_loglike{$a} } (keys %tab_loglike))
{
    print FIC_XML "<SETCAND new_ident=\"$i\" loglike=\"$tab_loglike{$i}\" freq=\"$tab_nfreq12[$i]\">\n";

    my $mterm;
    my $nlink;
    my $newidcpt;
    my $newid;
    my $relid;
    my ($id, $id1, $id2);

    #tableau de termes
    my %term_tab=();
    my @rel_link_list=();
    my %link_tab=();

    #on prepare les données
    #pour chaque candidat
    foreach $id (@{$new_index[$i]})
    {
	$newidcpt=0;

	#on recuper les infos du terme
	get_candidat($id, \%term_tab);

	#on recherche des nouveaux candidat (adj rel + neg )
	foreach $mterm (keys %{$term_tab{$id}})
	{
	    #si type=MODIF et contient nouvel adjectif relationnel, on cree un nouveau candidat
	    if($term_tab{$id}{$mterm}{'type'} =~ /MODIF/ && ($nlink=detect_new_candidat($mterm)) ne "")
	    {
		#si on n'a plus que un seul candidat
		if((keys %{$term_tab{$id}})>1)
		{
		    #on cree un nouveau candidat
		    $newid=$id."_".$newidcpt; $newidcpt++;
		    
		    $term_tab{$newid}{$mterm}=$term_tab{$id}{$mterm};
		    delete $term_tab{$id}{$mterm};
		    
		    #on ajoute un nouveau lien
		    $link_tab{$id}{$newid}=$nlink;

		}
	    }
	}

	#recherche des autres liens
	foreach $relid (keys %{$relation_type{$id}})
	{
	    #exception : le type de lien REL ne genere pas de nouveau candidat
	    if($relation_type{$id}{$relid} eq "REL")
	    {
		push @rel_link_list, ($id, $relid);
	    }
	    elsif($relation_type{$id}{$relid} ne "TIRET") #pas de lien TIRET
	    {
		$link_tab{$id}{$relid}=$relation_type{$id}{$relid};
		
	    }
	}
    }

    
    #integration des lien REL
    @rel_link_list= sort (@rel_link_list);
    $relid=shift @rel_link_list;
    # pour chaque relation REL a supprimer
    foreach $id (@rel_link_list)
    {
	#deplace les termes
	foreach $mterm (keys %{$term_tab{$id}} )
	{    
	    $term_tab{$relid}{$mterm}=$term_tab{$id}{$mterm}; 
	}
	delete $term_tab{$id};


	#met à jour les autres liens
	foreach $id2 (keys %{$link_tab{$id}})
	{
	    $link_tab{$relid}{$id2}=$link_tab{$id}{$id2};
	}
	foreach $id1 (keys %link_tab)
	{
	    if(exists $link_tab{$id1}{$id})
	    {
		$link_tab{$id1}{$relid}=$link_tab{$id1}{$id};
		delete $link_tab{$id1}{$id};
	    }
	}
    }
	
    #ecriture des liens
    foreach $id (keys %link_tab)
    {
	foreach $relid (keys %{$link_tab{$id}})
	{    
	    print FIC_XML "<LINK type=\"$link_tab{$id}{$relid}\" old_ident1=\"$id\" old_ident2=\"$relid\"><\/LINK>\n";
	}
    }

    #on ecrit les candidats
    #pour chaque terme candidat
    foreach $id (keys %term_tab)
    {
	print FIC_XML "\t<CAND old_ident=\"$id\">\n";

	#on ecrit l'ensemble des termes trouvés
	foreach $mterm (keys %{$term_tab{$id}})
	{
	    print FIC_XML "\t<$term_tab{$id}{$mterm}{'struct'} freq=\"$term_tab{$id}{$mterm}{'freq'}\">\n";
	    print FIC_XML "\t\t<$term_tab{$id}{$mterm}{'type'}> ";
	    print FIC_XML "<TERM> $mterm <\/TERM>\n";
	    print FIC_XML "\t\t<\/$term_tab{$id}{$mterm}{'type'}>\n";
	    print FIC_XML "\t<\/$term_tab{$id}{$mterm}{'struct'}>\n";
	}
	print FIC_XML "\t<\/CAND>\n";
    }
    print FIC_XML "<\/SETCAND>\n\n";
}
print FIC_XML "<\/LISTCAND>\n";

print "\n";

#### fermeture des fichiers


close(FIC_TRI);
close(FIC_RES);
#close(FIC_EXP2);
close(FIC_NIND);
close(FIC_TMP);
close(FIC_TMP2);
close(FIC_TMP3);
close(FIC_TMP3_BIS);
close(FIC_REL);
close(FIC_INV);
close(FIC_PREF);
close(FIC_ENS);
close(FIC_TIRET);
close(FIC_XML);





