#!/usr/bin/perl -C

########## DERNIERE MISE A JOUR 27/10/04

use integer;
use utf8;
#
#  
#############################################################################  
#                                                                           #
#                Extraction de terminologie et statistiques                 #
#                                                                           #
#############################################################################
#
#
#############################################################################
# Auteur :                                                                  #
#                                                                           #
# Béatrice Daille
#                                                                           #
#                                                                           #
#                                                                           #     
#############################################################################  

#Version du 5/12/2002 ou on a retire la catégorie gramamticale du PPE
# la version fr_stat_04_12_02.pl contient cette modification


#############################################################################
#      MODIFICATION 
#  Samuel DUFOUR-KOWALSKI
#  27/10/03
# regroupement des boucles de detection des liens morphologiques
# correction des formats de sorties
# correction bug tiret deuxiemme lemme
# correction règle é
#############################################################################


#############################################################################
#      MODIFICATION 
#  Samuel DUFOUR-KOWALSKI
#  27/10/04
#  
#  passage utf-8
#  réécriture des fonction de morphologie -> généricité
#############################################################################


# Utilisation des expressions régulières définies dans le fichier fr_def.pl 
require ("lib/fr_def.pl");

# Utilisation des derivations morphologiques définies dans le fichier fr_def2.pl 
require ("lib/fr_def2.pl");

# Utilisation des exceptions définies dans le fichier fr_def3.pl 
require ("lib/fr_def3.pl");


# Variables globales du programme  

# **********************************************************************
#  Tableau associatif pour l'enregistrement des couples de lemme
#                    Deb
# **********************************************************************


       my %Deb; # Tableau de hachage stockant les patrons trouves commencant par un lemme donne
                # ce tableau comporte trois cles: 
                # le lemme de debut : $Deb{$premierLemme}
                # le lemme de fin : $Deb{$premierLemme}{$dernierLemme}
                # la suite de lemmes : $Deb{$premierLemme}{$dernierLemme}{$chaineLemmes}

                # il sert a comptabiliser toutes les frequences, la longueur du patron, 
                # la suite de lemmes et l'indice y correspondant.
                # $Deb{'nb'} : la frequence totale d'occurrences de patrons rencontres
                # $Deb{$premierLemme}{'nb'} : la frequence du premier lemme au sein 
                #                               d'occurrences de patrons rencontrées
                # $Deb{$premierLemme}{$dernierLemme}{'nb'} : la frequence du couple de lemme
                # $Deb{$premierLemme}{$dernierLemme}{$chaineLemmes}[0] : la frequence de la suite
                #                                                        de lemmes
                # $Deb{$premierLemme}{'sommeLog'}: calcul de la diversite du premier lemme

                # le type de structure de base  rencontré : 
                # pour le premier lemme : $Deb{$premierLemme}{'struct'}
                # pour le couple : $Deb{$premierLemme}{$dernierLemme}{'struct'}
                # struct ::=  "na", "npn", "npna", "npnn", "npnng", "npnpn" ou "nv"
                
                # l'identifiant unique du couple de lemme
                # $Deb{$premierLemme}{$dernierLemme}{'id'}
                
                # 3/12/03 BD : rajout etiquette du deuxieme lemme pour regroupement
                #      morphologique après la structure na :
                # $Deb{$premierLemme}{$dernierLemme}{'struct'}{'etiq'}


      my %Fin; # Tableau de hachage stockant les patrons trouves finissant par un lemme donne
                # ce tableau comporte trois cles: le lemme de fin,  le lemme de debut 
                # et la suite de lemmes
                # il ne sert qu'a comptabiliser les frequences
 

       my %AdjRel; # tableau des adjectifs relationnels
                   # cle de hash : adjectif
                   # valeur : nom de base
                   # exemple : $AdjRel{alimentaire}= aliment 
       

       my %NomPref; # tableau des noms apparaissant avec un suffixe
                    # cle de hash : suffixenom
                    # valeur : nom
                    # exemple : $NomPref{semiindustriel}= industriel

       my %DerivNtoPp; # tableau des noms dérivés a partir d'un verbe ou ppe
                   # cle de hash : nom
                   # valeur : ppé
                   # exemple : $DerivNtoPp{grillade}= grillé 

       my %DerivNtoN ; # tableau des noms derives a partir d'un nom
                       #cle de hash nom derive
                       #nom de base
                       #exemple $DerivNtotN{appareilage} = appareil

       my %Mottiret; # tableau des mots apparaissant avec un tiret (non déjà enregisté)
                    # cle de hash : mottiret
                    # valeur : autre lemme du couple
                    # exemple : $Mottiret{semi-industriel}= usine
       
       # Récupération du nom du fichier passé un paramètre
       $parametre=$ARGV[0];  

       # Création du fichier dans lequel sera écrit le résultat de la recherche de patrons
       open(SORTIE, ">REA/temp.txt");

       # Création du fichier dans lequel sera écrit toutes les occurrences de patrons rencontrés
       open(SORTIE2, ">REA/temp2.txt");

       # Création du fichier dans lequel seront ecrits tous les adjectifs relationnels
       open(SORTIE3, ">REA/temp3.txt");

       # Création du fichier dans lequel seront ecrits tous les patrons comprenant des adjectifs relationnels
       open(SORTIE4, ">REA/relationnel.txt");

       # Création du fichier dans lequel seront ecrits tous les mots comprenant un tiret
       open(SORTIE5, ">REA/tiret.txt") ; 

       # Création du fichier dans lequel seront ecrits tous les patrons comprenant un prefixe
       open(SORTIE6, ">REA/prefixe.txt") ;
 
      # Création du fichier dans lequel seront ecrits tous les patrons comprenant une inversion
       open(SORTIE7, ">REA/inversion.txt") ;
 
      # Création du fichier dans lequel seront ecrits tous les patrons comprenant une derivation sur le Nom de tete
       open(SORTIE8, ">REA/ensemble.txt") ;


#####################################################################################################
#####################################################################################################
#                                          FONCTIONS                                                #
#####################################################################################################
#####################################################################################################

#####################################################################################################
# Fonction d'analyse de l'entrée                                                                    #
# supprime les balises et enregistre les info correspondates
#####################################################################################################
# Paramètres :                                                                                      # 
#  $_[0] : ligne à analyser                                                                         #
#####################################################################################################

$baliseAB=0;
sub AnalyseEntree
{
    my $ligne=shift @_;
    chomp($ligne); 
    
    #BALISE AB
    if($ligne =~ /<AN>/)
    { $baliseAB=1; }

    # recupère le n° de texte format 1
    if($baliseAB==1 && $ligne =~ /($DATE) ($SEP) ($REF)/) 
    { 
     	$annee = recupAnnee($1); 
     	$numTexte = recupNumText($3); 

	#supprime la ligne 
	$ligne="";
    } 

    if($ligne =~ /<\/AN>/)
    { $baliseAB=0; }
    
     # récupere le n° de phrase 
    if($ligne =~ /<ph_nb=[0-9]+>/) 
    { 
	$numPhrase = recupNumPhrase($ligne);
    } 
    
    if($ligne =~ /$TITRE/) 
     { 
	 $titre = 1;
     } 
    
    if($ligne =~ /$TEXTE/) 
    { 
	$titre = 0; 
     } 
    
    # enleve les tags 
    $ligne =~ s/<.+?>//g ; 
 
    return $ligne;
}

#####################################################################################################
# Fonction renvoyant l'annee                                                                        #
# $_[0] : date liee au texte                                                                        #
#####################################################################################################
sub recupAnnee
{ 
  my $date = $_[0];
  @num = split(/\//,$date); 
		 
  return $num[0]; 
}  

 
#####################################################################################################
# Fonction renvoyant le n° de texte                                                                 #
# $_[0] : reference du texte                                                                        #
#####################################################################################################
sub recupNumText 
{ 
  my $ref = $_[0];
  @num = split(/\//,$ref); 
		 
  return $num[0]; 
}  

       
#####################################################################################################
# Fonction renvoyant le n° de phrase                                                                #
# $_[0] : phrase entiere                                                                            #
#####################################################################################################
sub recupNumPhrase 
{ 
  my $phrase = $_[0];
  $phrase =~ s/<ph_nb=([0-9]+)>(.+?)/$2/g ; 
	 
  return $1; 
} 

#####################################################################################################
# Fonction qui enregistre les frequences                                                            #
#####################################################################################################
# Paramètres :                                                                                      # 
#  $_[0] : premier lemme                                                                            #
#  $_[1] : dernier lemme                                                                            #
#  $_[2] : chaine avec tous les lemmes                                                              #
#  $_[3] : type de la structure de base ("na", "npn", "npna", "npnn", "npnng", "npnpn" ou "nv")     #
#####################################################################################################

sub EnregistreFreq
{
  my $premierLemme = $_[0];  # premier lemme du patron
  my $dernierLemme = $_[1];  # dernier lemme du patron
  my $chaineLemmes = $_[2];  # chaine contenant le patron à stocker
  my $struct = $_[3];        # structure du patron
  #my $etiqAdj = $_[4];        # structure du patron

  # on comptabilise le nombre total de patrons
  if( exists $Deb{'nb'})
  {
      $Deb{'nb'} += 1;
  }
  else
  {
      $Deb{'nb'} = 1;
  }

  # on tient a jour le flag qui dit quelles structures on a deja rencontrees
  # 1 si on a rencontre na ou npna ou nv
  # 2 si on a rencontre npn ou npnn ou npnpn ou npnng
  # 3 si on a rencontre soit cas 1 soit cas 2
  # BD : A reprendre incomplet pour des regroupements plus fin
  # Proposition : na 1 ; npn 2 ; npna 4 ; nv 8 ; nn 16 ; npnpn 32 ; npnn, npnng 64;

  # si l'on a deja rencontre ce premier lemme en debut
  if( exists $Deb{$premierLemme}{'struct'})
  { 
    SWITCH: {

      if ($struct eq "na")
      {   $Deb{$premierLemme}{'struct'} = $Deb{$premierLemme}{'struct'} | "1" ; last SWITCH ; };
      if ($struct eq "npn") 
      {   $Deb{$premierLemme}{'struct'} = $Deb{$premierLemme}{'struct'} | "2" ; last SWITCH ; };
      if ($struct eq "npna") 
      {   $Deb{$premierLemme}{'struct'} = $Deb{$premierLemme}{'struct'} | "4" ; last SWITCH ; };
      if ($struct eq "nv")
      {   $Deb{$premierLemme}{'struct'} = $Deb{$premierLemme}{'struct'} | "8" ; last SWITCH ; } ;
      if ($struct eq "nn")
      {   $Deb{$premierLemme}{'struct'} = $Deb{$premierLemme}{'struct'} | "16" ; last SWITCH ; };
      if ($struct eq "npnpn")  
      {   $Deb{$premierLemme}{'struct'} = $Deb{$premierLemme}{'struct'} | "32" ; last SWITCH ; };
      if  ( ($struct eq "npnn") || ($struct eq "npnng") )
      {   $Deb{$premierLemme}{'struct'} = $Deb{$premierLemme}{'struct'} | "64" ; last SWITCH ; }; 
  }#fin SWITCH
  }#finsi premier lemme de début
  # si l'on n'a pas encore rencontre ce premier lemme en debut 
  else
  {
      # on initialise le flag
    SWITCH: {

      if ($struct eq "na")
      {   $Deb{$premierLemme}{'struct'} = "1" ; last SWITCH ; };
      if ($struct eq "npn") 
      {   $Deb{$premierLemme}{'struct'} = "2" ; last SWITCH ; };
      if ($struct eq "npna") 
      {   $Deb{$premierLemme}{'struct'} = "4" ; last SWITCH ; };
      if ($struct eq "nv")
      {   $Deb{$premierLemme}{'struct'} = "8" ; last SWITCH ; } ;
      if ($struct eq "nn")
      {   $Deb{$premierLemme}{'struct'} = "16" ; last SWITCH ; };
      if ($struct eq "npnpn")  
      {   $Deb{$premierLemme}{'struct'} = "32" ; last SWITCH ; };
      if  ( ($struct eq "npnn") || ($struct eq "npnng") )
      {   $Deb{$premierLemme}{'struct'} =  "64" ; last SWITCH ; }; 
  }#fin SWITCH
  }



  # si l'on a deja rencontre ce premier lemme en debut
  if( exists $Deb{$premierLemme}{'nb'})
  { 
      $Deb{$premierLemme}{'nb'} += 1;
  }
  # si l'on n'a pas encore rencontre ce premier lemme en debut 
  else
  {
      $Deb{$premierLemme}{'nb'} = 1;
      # on initialise cette valeur utile pour la diversite
      $Deb{$premierLemme}{'sommeLog'} = 0;
  }



  # si l'on a deja rencontre ce dernier lemme en fin
  if( exists $Fin{$dernierLemme}{'nb'})
  { 
      $Fin{$dernierLemme}{'nb'} += 1;
  }
  # si l'on n'a pas encore rencontre ce dernier lemme en fin
  else
  {
      $Fin{$dernierLemme}{'nb'} = 1;
      # on initialise cette valeur utile pour la diversite
      $Fin{$dernierLemme}{'sommeLog'} = 0;
  }


  # on tient a jour le flag qui dit quelles structures on a deja rencontrees
  # si l'on a deja rencontre ce premier lemme en debut
  if( exists $Deb{$premierLemme}{$dernierLemme}{'struct'})
  { 
    SWITCH: {

      if ($struct eq "na")
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = $Deb{$premierLemme}{$dernierLemme}{'struct'} | "1" ; last SWITCH ; };
      if ($struct eq "npn") 
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = $Deb{$premierLemme}{$dernierLemme}{'struct'} | "2" ; last SWITCH ; };
      if ($struct eq "npna") 
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = $Deb{$premierLemme}{$dernierLemme}{'struct'} | "4" ; last SWITCH ; };
      if ($struct eq "nv")
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = $Deb{$premierLemme}{$dernierLemme}{'struct'} | "8" ; last SWITCH ; } ;
      if ($struct eq "nn")
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = $Deb{$premierLemme}{$dernierLemme}{'struct'} | "16" ; last SWITCH ; };
      if ($struct eq "npnpn")  
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = $Deb{$premierLemme}{$dernierLemme}{'struct'} | "32" ; last SWITCH ; };
      if  ( ($struct eq "npnn") || ($struct eq "npnng") )
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = $Deb{$premierLemme}{$dernierLemme}{'struct'} | "64" ; last SWITCH ; }; 
  }#fin SWITCH
  }
  # si l'on n'a pas encore rencontre ce premier lemme en debut 
  else
  {

    SWITCH: {

      if ($struct eq "na")
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = "1" ; 
          #$Deb{$premierLemme}{$dernierLemme}{'struct'}{'etiq'} = $etiqAdj ; 
          last SWITCH ; };
      if ($struct eq "npn") 
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = "2" ; last SWITCH ; };
      if ($struct eq "npna") 
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = "4" ; last SWITCH ; };
      if ($struct eq "nv")
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = "8" ; last SWITCH ; } ;
      if ($struct eq "nn")
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = "16" ; last SWITCH ; };
      if ($struct eq "npnpn")  
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} = "32" ; last SWITCH ; };
      if  ( ($struct eq "npnn") || ($struct eq "npnng") )
      {   $Deb{$premierLemme}{$dernierLemme}{'struct'} =  "64" ; last SWITCH ; }; 
  }#fin SWITCH
  } 



  if( exists $Deb{$premierLemme}{$dernierLemme}{'nb'})
  { 
      $Deb{$premierLemme}{$dernierLemme}{'nb'} += 1;
      # on actualise les valeurs "nb" et "sommeLog" utiles pour la diversite
      $val = $Deb{$premierLemme}{$dernierLemme}{'nb'};
       
      no integer;
      my $temp = $val*1000*(log $val) - ($val-1)*1000*(log ($val-1));
      use integer;

      $Deb{$premierLemme}{'sommeLog'} += $temp;
  }
  else
  {
      $Deb{$premierLemme}{$dernierLemme}{'nb'} = 1;
      $Deb{$premierLemme}{$dernierLemme}{'id'} = $ident ;
      $ident++;
  }


  if( exists $Fin{$dernierLemme}{$premierLemme}{'nb'})
  { 
      $Fin{$dernierLemme}{$premierLemme}{'nb'} += 1;
     # on actualise les valeurs "nb" et "sommeLog" utiles pour la diversite
      my $val = $Fin{$dernierLemme}{$premierLemme}{'nb'};

      no integer;
      my $temp = $val*1000*(log $val) - ($val-1)*1000*(log ($val-1));
      use integer;

      $Fin{$dernierLemme}{'sommeLog'} += $temp;
  }
  else
  {
      $Fin{$dernierLemme}{$premierLemme}{'nb'} = 1;
      $Fin{$dernierLemme}{$premierLemme}{'id'} = $ident-1 ;
  }


  # si l'on a deja rencontre le patron
  if( exists $Deb{$premierLemme}{$dernierLemme}{$chaineLemmes})
  { 
      # on incremente la frequence liee au patron
      $Deb{$premierLemme}{$dernierLemme}{$chaineLemmes}[0] += 1;
  }
  # si l'on n'a pas encore rencontre le patron
  else
  {
      # On initialise la frequence du patron
      $Deb{$premierLemme}{$dernierLemme}{$chaineLemmes}[0] = 1;
  }

}


#####################################################################################################
# Fonction qui simplifie un patrons                                                                 #
#####################################################################################################
# Paramètres :                                                                                      #   
#  $_[0] : chaine avec tous les lemmes                                                              #
#  $_[1] : type du patron ("BASE", "MODIF", "COORD", "ENUM" ou "ATTR")                              # 
#  $_[2] : type de la structure de base ("na", "npn", "npna", "npnn", "npnpn", "npnng" ou "nv")              #
#  $_[3] : nombre de mots du patron                                                                 #
#  $_[4] : premier lemme                                                                            #
#####################################################################################################
sub Simplifie
{

    my $chaineLemmes = $_[0];
    my $type = $_[1];
    my $struct = $_[2];
    my $l = $_[3];
    my $premierLemme = $_[4];  # premier lemme du patron
 
    SWITCH :
    {
          # Si le patron a une structure de type NA ou NPNA ou NPNN ou NPNPN
          # on garde comme chaine le nom et le dernier adjectif (ou le dernier nom si c'est un NPNN)
	  if  (($struct eq "na") || ($struct eq "npna") || ($struct eq "npnpn") || ($struct eq "npnn"))
	  {
	      my @chaineTemp = split(/ /,$chaineLemmes);
	      $chaineLemmes = $premierLemme." ".$chaineTemp[$l-1];
	      last SWITCH;
	  }

          # Si le patron a une structure de type NPNNG (le dernier nom entre guillemet)
          # on garde comme chaine le nom et le dernier nom
	  if  ($struct eq "npnng")
	  {
	      my @chaineTemp = split(/ /,$chaineLemmes);
	      $chaineLemmes = $premierLemme." ".$chaineTemp[$l-2];
	      last SWITCH;
	  }

          # Si le patron a une structure de type NaV, on garde comme chaine le nom et le verbe
	  if  ($struct eq "nv")
	  {
	      my @chaineTemp = split(/ /,$chaineLemmes);
	      $chaineLemmes = $premierLemme." ".$chaineTemp[2];
	      last SWITCH;
	  }


          # Si le patron a une structure de type NPN et est de type COORD ou ENUM
          # on garde comme chaine le patron de base de type NPN
	  if  (($struct eq "npn") && (($type eq "COORD") || ($type eq "ENUM")))
	  {
	      my @chaineTemp = split(/ /,$chaineLemmes);
	      $chaineLemmes = $premierLemme;
              my $j=$l-1;
      
	      while ($chaineTemp[$j] !~ /^($LEMME_PREPOSITION)/)
	      { 
		  $j--;
	      }

              for ($i=$j; $i<$l; $i++)
              {
                  $chaineLemmes = $chaineLemmes." ".$chaineTemp[$i]
              }

	      last SWITCH;
	  }


          # Si le patron a une structure de type NPN et est de type MODIF
          # on garde comme chaine le patron de base de type NPN
	  if  (($struct eq "npn") && ($type eq "MODIF"))
	  {
	      my @chaineTemp = split(/ /,$chaineLemmes);
	      $chaineLemmes = $premierLemme;
              my $j=$l-1;
      
	      while ($chaineTemp[$j] !~ /^($LEMME_PREPOSITION)/ )
	      { 
		  $j--;
	      }

	      if ($chaineTemp[$j-1] =~ /^($LEMME_PREPOSITION)/)
	      { 
		  $j--;
	      }

              for ($i=$j; $i<$l; $i++)
              {
                  $chaineLemmes = $chaineLemmes." ".$chaineTemp[$i]
              }

	      last SWITCH;
	  }
    }

    return $chaineLemmes;
}





#####################################################################################################
# Fonction qui reconstruit la suite de flexions                                                     #
#####################################################################################################
# Paramètres :                                                                                      #   
#  $_[0] : tableau contenant les mots du patron                                                     #
#  $_[1] : nombre de mots du patron                                                                 #
#####################################################################################################

sub RecupFlex
{
  # on recupere dans des variables les parametres d'appel de la fonction
  my ($monTab) = $_[0];      # tableau contenant les mots du patron 
  my $l = $_[1];             # nombre de mots du patron

  my $temp = $monTab->[0][0];

  # pour tous les mots du patron
  for($j=1; $j < $l; $j++)
  {
	  # on recupere la suite de flexions
	  $temp = $temp." ".$monTab->[$j][0];
  }
  return $temp;
}



#####################################################################################################
# Fonction qui reconstruit la suite d'etiquettes                                                    #
#####################################################################################################
# Paramètres :                                                                                      #   
#  $_[0] : tableau contenant les mots du patron                                                     #
#  $_[1] : nombre de mots du patron                                                                 #
#####################################################################################################

sub RecupEtiq
{
  # on recupere dans des variables les parametres d'appel de la fonction
  my ($monTab) = $_[0];      # tableau contenant les mots du patron 
  my $l = $_[1];             # nombre de mots du patron

  my $temp = $monTab->[0][1];

  # pour tous les mots du patron
  for($j=1; $j < $l; $j++)
  {
	  # on recupere la suite d'etiquettes
	  $temp = $temp." ".$monTab->[$j][1];
  }

  return $temp;
}



#####################################################################################################
# Fonction qui reconstruit la suite de lemmes                                                       #
#####################################################################################################
# Paramètres :                                                                                      #   
#  $_[0] : tableau contenant les mots du patron                                                     #
#  $_[1] : nombre de mots du patron                                                                 #
#####################################################################################################

sub RecupLem
{
  # on recupere dans des variables les parametres d'appel de la fonction
  my ($monTab) = $_[0];      # tableau contenant les mots du patron 
  my $l = $_[1];             # nombre de mots du patron

  my $temp = $monTab->[0][2];

  # pour tous les mots du patron
  for($j=1; $j < $l; $j++)
  {
	  # on recupere la suite de lemmes
	  $temp = $temp." ".$monTab->[$j][2];
  }
  return $temp;
}


#####################################################################################################
# Fonction qui stocke un patron trouvé                                                              #
#####################################################################################################
# Paramètres :                                                                                      #   
#  $_[0] : tableau contenant les mots du patron                                                     #
#  $_[1] : nombre de mots du patron                                                                 #
#  $_[2] : type du patron ("BASE", "MODIF", "COORD", "ENUM" ou "ATTR")                              # 
#  $_[3] : type de la structure de base ("na", "npn", "npna", "npnn", "npnpn", "npnng" ou "nv")     #
#  $_[4] : chaine avec tous les lemmes                                                              #
#  $_[5] : premier lemme                                                                            #
#  $_[6] : dernier lemme                                                                            #
#####################################################################################################

sub RemplitPatron
{
  # on recupere dans des variables les parametres d'appel de la fonction
  my ($monTab) = $_[0];      # tableau contenant les mots du patron 
  my $l = $_[1];             # nombre de mots du patron
  my $type = $_[2];          # type d'occurrences rencontrées : base, modif, coord
  my $struct = $_[3];        # structure de base 
  my $chaineLemmes =  $_[4]; # chaine contenant le patron à stocker
  my $premierLemme = $_[5];  # premier lemme du patron
  my $dernierLemme = $_[6];  # dernier lemme du patron
  #my $etiqAdj = $_[7] ;      # etiquette de l'adjectif (ADJ ou PPE)

  # on recupere le patron simplifie
  $chaineLemmes = Simplifie($chaineLemmes,$type,$struct,$l,$premierLemme);

  # on comptabilise les frequences, on calcule le loglike au fur et a mesure et on calcule des valeurs utiles a la diversite 
  #EnregistreFreq($premierLemme,$dernierLemme,$chaineLemmes,$struct,$etiqAdj);
  
  EnregistreFreq( $premierLemme,$dernierLemme,$chaineLemmes,$struct );
  #on recupere la suite de flexions
  my $suiteFlex = RecupFlex($monTab,$l);

  #on recupere la suite d'etiquettes
  my $suiteEtiq = RecupEtiq($monTab,$l);

  #on recupere la suite de lemmes
  my $suiteLem = RecupLem($monTab,$l);

  # on ecrit l'indice d'apparition, les flexions, les etiquettes, la structure du patron, le type du patron, le numero de texte et le numero de phrase
  print SORTIE2 $premierLemme," ",$dernierLemme," ",$Deb{$premierLemme}{$dernierLemme}{'id'}," --- ",$suiteFlex," --- ",$suiteEtiq," --- ",$suiteLem," --- ",$struct, " --- ",$type," --- ",$annee," --- ",$numTexte," --- ",$numPhrase," --- ",$titre,"\n";
}


#####################################################################################################
# Fonction qui rend compte de l'avancement                                                          #
#####################################################################################################
sub Avancement
{
  # marqueur de temps pour se rendre compte de l'avancement du parcours
  $compte ++;

  # affiche le temps pris tous les 1000 patrons trouves
  if (($compte % 1000) == 1)
  {
        my $newtemps = (time);
        my $modu = ($compte - 1) / 1000;
        print STDOUT $modu," ",$newtemps - $temps,"\n";
        $temps = $newtemps;
  }
}


#####################################################################################################
# Fonction calculant le mot reel de debut d'un patron (enleve l'article...)                         #
#####################################################################################################
#  $_[0] : tableau contenant les mots du patron                                                     #
#  $_[1] : type de patron reconnu ("COORD", "MODIF", "BASE", "ENUM", "COORDTETE", "ATTR")           #
#####################################################################################################
sub CalculeMotDeb
{ 
  my ($monTab) = $_[0];      # tableau contenant les mots du patron 
  my $patron = $_[1];        # type de patron reconnu (COORD, MODIF, BASE, ENUM, COORDTETE, ATTR)


  # la 1ère clé est la concaténation des lemmes du 1er et du dernier mot du patron (séparés par un espace)
  # sauf pour les coordinations de tete ou c'est la concaténation des lemmes du 2e ou du 3e("de la N et...") et du dernier mot du patron  
  if( $patron eq "COORDTETE")
  {
      if(($monTab->[1][2] eq "la") || ($monTab->[1][2] eq "l'")) 
      {
	  # test si ce n'est une fausse coordination comme "l'independance et l'independance conditionnelle"
          if(($monTab->[5][2] eq "la") || ($monTab->[5][2] eq "l'"))
          {
               if($monTab->[2][2] eq $monTab->[6][2]){return -1;}
          }
          else
          {
               if($monTab->[2][2] eq $monTab->[5][2]){return -1;}
          }

          $motdeb = $monTab->[2][2];
      }
      else
      {
	  # test si ce n'est une fausse coordination comme "l'independance et l'independance conditionnelle"
          if(($monTab->[4][2] eq "la") || ($monTab->[4][2] eq "l'"))
          {
               if($monTab->[1][2] eq $monTab->[5][2]){return -1;}
          }
          else
          {
               if($monTab->[1][2] eq $monTab->[4][2]){return -1;}
          }

          $motdeb = $monTab->[1][2];
      }
   }
  else
  {
      $motdeb = $monTab->[0][2];   
  }

  return $motdeb
}


#####################################################################################################
# Fonction qui traite tous les mots du patron :                                                     #
# Remplit les tableaux de correspondance tabLems et tabFlex                                         #
#####################################################################################################
#  $_[0] : tableau contenant tous les mots du patron à stocker                                      #
#  $_[1] : nombre de mots du patron                                                                 #
#####################################################################################################
sub TraiteMots
{ 
  my ($TabMots) = $_[0];      # tableau contenant les mots du patron 
  my $long = $_[1];           # nombre de mots du patron

  my @mot=(); # tableau à 2 dimensions [nombre de mots du patron][3] qui stocke les flexion, étiquette et lemme de chaque mot du patron

  # pour chaque mot de l'expression on sépare flexion, étiquette et lemme
  for($j=0; $j<$long; $j++)
  {
	# cas particuler : un signe de ponctuation (virgule...)
	if($TabMots->[$j] =~ /($CHRS)\/($CHRS)/)
	{
	    $mot[$j][0]= $1;     #flexion
	    $mot[$j][1]= "CHRS"; #etiquette
	    $mot[$j][2]= $2;     #lemme
	}
	# cas général : un mot
	else
	{
	    my @temp=split(/\//,$TabMots->[$j]);
	    $mot[$j][0]= $temp[0]; #flexion

	    my @eti = split(/:/,$temp[1]); 
	    $mot[$j][1]= $eti[0]; #etiquette

	    $mot[$j][2] = $temp[2]; #lemme
	    $lem = $temp[2]; #lemme 
	}

        $flex = $mot[$j][0]; #flexion 
        $lem = $mot[$j][2]; #lemme 
  }

  return (\@mot);
}


#####################################################################################################
# Fonction qui stocke un patron trouvé                                                              #
#####################################################################################################
# Paramètres :                                                                                      #
#  $_[0] : chaine contenant le patron à stocker                                                     #
#  $_[1] : nombre de mots du patron                                                                 #
#  $_[2] : type de la structure de base ("na", "npn", "npna", "npnn", "npnng" ou "nv")              #
#  $_[3] : type de patron reconnu ("COORD", "MODIF", "BASE", "ENUM", "COORDTETE", "ATTR")           #
#####################################################################################################
sub PremierDernier
{
    # on recupere dans des variables les parametres d'appel
    my $chainePatron = $_[0]; # chaine contenant le patron à stocker
    my $long = $_[1];    # nombre de mots du patron
    my $struct = $_[2];    # structure de base ("na", "npn","npna", "npnn", "npnpn", "npnng" ou "nv")
    my $patron = $_[3];  # type de patron reconnu (COORD, MODIF, BASE, ENUM, COORDTETE, ATTR)
    
    #Annule : Rajout etiquette adj pour na
    #my $etiqAdj = $_[4] ;

    # on rend compte de l'avancement
    Avancement();

    my @chaines=split(/ /,$chainePatron); # stockage de tous les mots du patron dans un tableau 

    my ($monTab) = TraiteMots(\@chaines,$long);

    CAS_DE_SORTIE:
    {
	  # on recupere le mot reel de debut
	  my $motdeb = CalculeMotDeb($monTab,$patron);

	  # si l'on affaire avec une fausse coordination de tete, on ne traite pas le patron
	  if ($motdeb eq "-1") {last CAS_DE_SORTIE} 

	  # A partir de maintenant on traite pareillement les COORD et les COORDTETE donc on ne fait plus de distiction
	  if( $patron eq "COORDTETE")
	  {
	      $patron = "COORD";
	  }

	  # on reconstruit la chaine de tous les lemmes du patron qui va servir de cle pour %Deb 
	  my $chaineLemmes = $monTab->[0][2];       

	  for ($i=1; $i<$#chaines+1; $i++)
	  {
	      $chaineLemmes = $chaineLemmes." ".$monTab->[$i][2];
	  }

	  my $dernierLemme = $monTab->[$long-1][2];

	  if ($struct eq "npnng")
          {
	      $dernierLemme = $monTab->[$long-2][2];
	  }

	  # on appelle la fonction qui enregistre toutes les donnees relatives au patron
	  #RemplitPatron($monTab,$long,$patron,$struct,$chaineLemmes,$motdeb,$dernierLemme,$etiqAdj);
	  RemplitPatron($monTab,$long,$patron,$struct,$chaineLemmes,$motdeb,$dernierLemme);
    } # fin de CAS_DE_SORTIE
    
} # fin de la fonction PremierDernier


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
      


#####################################################################################################
# Fonction traitant les bases de structure "na", "npn, "npna"", "npnpn", "npnn", "npnng" ou "nv"             #
#####################################################################################################
# Paramètres :                                                                                      #
#  $_[0] : patron à traiter (base de structure "na","npn", "npna", "npnn", "npnpn", "npnng" ou "nv")         # 
#  $_[1] : structure de la base ("na","npn", "npna", "npnn", "npnpn", "npnng" ou "nv")                       #
#                                                                                                   #
# Retourne le nombre de mots que contient le patron   ($nb)                                         #
#                                                                                                   #
#####################################################################################################
sub traiteBase
{
  my $chaine = $_[0]; # récupération du patron à traiter
  my $struct = $_[1]; # récupération de la structure ("na","npn", "npna", "npnpn", "npnn", "npnng" ou "nv")

  my $type="BASE";
  
  my @tableau = split(/ /,$chaine); # stockage de tous les mots du patron dans un tableau
  my $nbM = $#tableau+1; # récupèration du nombre de mots que contient le patron
  my $etiAdj = "" ;     # récupération de l'étiquette de l'adjectif PPE ou ADJ
 
  CAS_DE_SORTIE: {


     if ($struct eq "na")
      {
	  my @nomNA = split(/\//,$tableau[0]); # recuperation du nom
	  my @adjNA = split(/\//,$tableau[1]); # recuperation de l'adjectif

	  my @etinomNA = split(/:/,$nomNA[1]); # recuperation de l'etiquette pour le nom
	  my @etiadjNA = split(/:/,$adjNA[1]); # recuperation de l'etiquette pour l'adjectif

          if ( $etiadjNA[0] =~ /PAR/ )
	  {
	      $etiAdj = "PPE" ;
	  }
	  else
	  {
	      $etiAdj = "ADJ" ;
	  }

	  if ( (($etinomNA[1] eq "m") && ($etiadjNA[1] eq "f")) ||
	       (($etinomNA[1] eq "f") && ($etiadjNA[1] eq "m")) ||
	       (($etinomNA[2] eq "s") && ($etiadjNA[2] eq "p")) ||
	       (($etinomNA[2] eq "p") && ($etiadjNA[2] eq "s"))  ) # tests pour l'accord en genre et en nombre entre le nom et l'adjectif
	  {
	      last CAS_DE_SORTIE;
	  }
      }

      if ($struct eq "npn")
      {
	  my $nom1 = $tableau[0]; # recuperation du nom
	  my $nom2 = $tableau[2]; # recuperation du nom

	  if (   (($nom1 =~ /^($EXCEPTION_QUANT)/) || ($nom2 =~ /^($EXCEPTION_QUANT)/))  # tests pour eviter les quantifieurs
              || (($nom1 =~ /^($EXCEPTION_PREP)/)  || ($nom2 =~ /^($EXCEPTION_PREP)/)) ) # tests pour eviter les noms qui font partie de prepositions complexes ("en fonction de")
	  {
	      last CAS_DE_SORTIE;
	  }
      }

      #PremierDernier($chaine,$nbM, $struct, $type, $etiAdj); # enregistrement du patron trouvé
     PremierDernier($chaine,$nbM, $struct, $type ); # enregistrement du patron trouvé
  }

  return $nbM; # Retourne le nombre de mots que contient le patron
}


#####################################################################################################
# Fonction traitant les modifications de structure "npn"                                            #
#####################################################################################################
# Paramètres :                                                                                      #
#  $_[0] : patron à traiter (modification de structure "npn")                                       #  
#                                                                                                   #
# Retourne le nombre de mots que contient le patron   ($nb)                                         #
#                                                                                                   #
#####################################################################################################

sub traiteModifNPN
{
  my $chaine = $_[0]; # récupération du patron à traiter
  my $type="MODIF";
  my $struct="npn";

  my @tableau = split(/ /,$chaine); # stockage de tous les mots du patron dans un tableau
  my $nbM = $#tableau+1; # récupèration du nombre de mots que contient le patron

  #PremierDernier($chaine, $nbM, $struct, $type, "" ); # enregistrement du patron trouvé
  PremierDernier($chaine, $nbM, $struct, $type ); # enregistrement du patron trouvé

  # Recherche de l'indice de la dernière PREP ou DTC appartenant au patron
  my $i = $#tableau;
  while(( ! ((($tableau[$i]." ") =~ /$PREP/) || (($tableau[$i]." ") =~ /$PREPDETOTH/) || (($tableau[$i]." ") =~ /$DET_CONT/)))
	 && ($i > 0))
  {
    $i = $i-1;
    $taille = $i;	       
  }

  # Construction de la sous chaine (du 1er mot du patron jusqu'au mot précédent la dernière PREP ou DTC)
  # sur laquelle la recherche de sous patrons va etre lancée
  my $lignemodif = $tableau[0];
  for ($j=1;$j<$taille;$j++) 
  {
    $lignemodif = $lignemodif." ".$tableau[$j];
  }

  # Recherche de patrons (Modifications et Bases) dans la sous-chaine
  ExtraitModif($lignemodif);

  return $nbM; # Retourne le nombre de mots que contient le patron
}


#####################################################################################################
# Fonction traitant les modifications de structure "npna"                                            #
#####################################################################################################
# Paramètres :                                                                                      #
#  $_[0] : patron à traiter (modification de structure "npna")                                       #  
#                                                                                                   #
# Retourne le nombre de mots que contient le patron   ($nbM)                                         #
#                                                                                                   #
#####################################################################################################

sub traiteModifNPNA
{
  my $chaine = $_[0]; # récupération du patron à traiter
  my $type="MODIF";
  my $struct="npna";

  my @tableau = split(/ /,$chaine); # stockage de tous les mots du patron dans un tableau
  my $nbM = $#tableau+1; # récupèration du nombre de mots que contient le patron

  #PremierDernier($chaine, $nbM, $struct, $type, ""); # enregistrement du patron trouvé
  PremierDernier($chaine, $nbM, $struct, $type ); # enregistrement du patron trouvé

  # Recherche de l'indice de la dernière PREP appartenant au patron
  my $i = $#tableau;
  while( (($tableau[$i]." ") !~ /$PREP/ ) && ($i > 0) )
  {
    $i = $i-1;
    $taille = $i;	       
  }

  # Construction de la sous chaine (du 1er mot du patron jusqu'au mot précédent la dernière PREP ou DTC)
  # sur laquelle la recherche de sous patrons va etre lancée
  my $lignemodif = $tableau[0];
  for ($j=1;$j<$taille;$j++) 
  {
    $lignemodif = $lignemodif." ".$tableau[$j];
  }

  # Recherche de patrons (Modifications et Bases) dans la sous-chaine
  ExtraitModif($lignemodif);

  return $nbM; # Retourne le nombre de mots que contient le patron
}



#####################################################################################################
# Fonction traitant les modifications de structure "na"                                             #
#####################################################################################################
# Paramètres :                                                                                      #
#  $_[0] : patron à traiter (modification de structure "na")                                        #  
#                                                                                                   #
# Retourne le nombre de mots que contient le patron   ($nbM)                                         #
#                                                                                                   #
#####################################################################################################

sub traiteModifNA
{
  my $chaine = $_[0]; # récupération du patron à traiter

  my $type="MODIF";
  my $struct="na";

  my @tableau = split(/ /,$chaine); # stockage de tous les mots du patron dans un tableau
  my $nbM = $#tableau+1; # récupération du nombre de mots que contient le patron
#  my $etiAdj = "" ;     # récupération de l'étiquette de l'adjectif PPE ou ADJ

  @nomNAA = split(/\//,$tableau[0]);  # recuperation du nom
  @adjderNAA = split(/\//,$tableau[$#tableau]); # recuperation du dernier adjectif

  @etinomNAA = split(/:/,$nomNAA[1]); # recuperation de l'etiquette pour le nom
  @etiadjderNAA = split(/:/,$adjderNAA[1]); # recuperation de l'etiquette pour le dernier adjectif

#      if ( $etinomNAA[0] =~ /PAR/ )
#	  {
#	      $etiAdj = "PPE" ;
#	  }
#	  else
#	  {
#	      $etiAdj = "ADJ" ;
#	  }


  if (! ( (($etinomNAA[1] eq "m") && ($etiadjderNAA[1] eq "f")) ||
          (($etinomNAA[1] eq "f") && ($etiadjderNAA[1] eq "m")) ||
          (($etinomNAA[2] eq "s") && ($etiadjderNAA[2] eq "p")) ||
          (($etinomNAA[2] eq "p") && ($etiadjderNAA[2] eq "s")) )  ) # tests pour l'accord en genre et en nombre entre le nom et le dernier adjectif
  {
    #PremierDernier($chaine, $nbM, $struct, $type, $etiAdj); # enregistrement du patron trouvé
    PremierDernier($chaine, $nbM, $struct, $type ); # enregistrement du patron trouvé
  }

	     
  # Recherche de l'indice de l'avant-dernier adjectif rencontré dans le patron
  # Cela permet de savoir sur quelle chaine lancer la recherche de patron :
  # c'est à dire : du 1er mot du patron jusqu'à l'avant dernier adjectif
  my $compteur = 0; # compte le nombre d'adjectifs rencontrés en partant de la fin du patron
  my $i = $#tableau;
  while (($compteur < 2) && ($i > 0))
  {
    if (($tableau[$i]." ") =~ /$ADJP/)
    {
      $compteur= $compteur +1;
    }
    $taille = $i;
    $i = $i-1;  
  }

  # Construction de la sous chaine (du 1er mot du patron jusqu'à l'avant dernier adjectif)
  # sur laquelle on va lancer la recherche de sous patrons
  my $lignemodif = $tableau[0];
  for ($j=1;$j<$taille+1;$j++)
  {
    $lignemodif = $lignemodif." ".$tableau[$j];
  }

  # Recherche de patrons (Modifications et Bases) dans la sous-chaine
  ExtraitModif($lignemodif);

  return $nbM; # Retourne le nombre de mots que contient le patron
}




#####################################################################################################
# Fonction qui recherche une modification                                                           #
#####################################################################################################
# Paramètres :                                                                                      #
#  $_[0] : chaine pour laquelle la recherche de modification va etre effectuée                      #
#####################################################################################################

sub ExtraitModif
{
  my $modification = $_[0];     # la chaine pour laquelle la recherche va etre effectuée


  $modification = " ".$modification." " ;

  SWITCH: {

      # on cherche les modifications de type "npna"
      if ($modification =~ /^ ($MODIFNPNA)(.*)$/)
      {
	my $t = traiteModifNPNA($1);
	last SWITCH;
      }


      # on cherche les modifications de type "npn"
      if ($modification =~ /^ ($MODIFNPN)(.*)$/)           
      {
	my $t = traiteModifNPN($1);
	last SWITCH;
      }

      # on cherche les modifications de type "na"
      if ($modification =~ /^ ($MODIFNA)(.*)$/)
      {
	my $t = traiteModifNA($1);
	last SWITCH;
      }

      # on cherche les base
      ExtraitBase($modification);
  }
}




#####################################################################################################
# Fonction qui recherche une base présente au début d'un patron passé en paramètre                  #
#####################################################################################################
# Paramètres :                                                                                      #
#  $_[0] : chaine pour laquelle la recherche de base va etre effectuée                              #
#####################################################################################################

sub ExtraitBase
{
  $chaine1 = $_[0]; # chaine pour laquelle la recherche de base va etre effectuée
 
    SWITCH: {

      if($chaine1 =~ /^ ($BASENA)(.*)$/)
      {  
	my $t = traiteBase($1,"na");
	last SWITCH;
      } 

      if($chaine1 =~ /^ ($BASENPNA)(.*)$/)
      {  
	my $t = traiteBase($1,"npna");
	last SWITCH;
      } 

       if($chaine1 =~ /^ ($BASENPN)(.*)$/)
      {
	my $t = traiteBase($1,"npn");
	last SWITCH;
      }

       if($chaine1 =~ /^ ($BASENV)(.*)$/)
       {
	 my $t = traiteBase($1,"nv");
	 last SWITCH;
       } 

    }
}



#####################################################################################################
#####################################################################################################
#                                          PROGRAMME PRINCIPAL                                      #
#####################################################################################################
#####################################################################################################


$ident = 0;
$temps = (time);      
$compte = 0;

print "\nParcours du texte : recherche de patrons\n";

open(FIC2, $parametre) || die("fichier non trouve $!"); #ouverture du fichier en lecture  


foreach (<FIC2>) 
{ 
   
    #analyse l'entree
    $pointeur=AnalyseEntree($_);

    next if( $pointeur =~ m/^$/); 

     # tant que la fin de la ligne n'est pas atteinte, la recherche continue
     while($pointeur !~ /^$/)
     {

       $machaine=" ".$pointeur;

       SWITCH: {

       # RECHERCHE DE COORDINATION DE TETE DE TYPE "na"

       if($machaine =~ /^ ($COORDTETENA)(.*)$/)   
       {
	 $c=$1;    	    # récupération du patron trouvé dans $c
	 $type="COORDTETE";
	 $struct="na";
	 @tableau1 = split(/ /,$c); # stockage de tous les mots du patron dans un tableau
	 $t = $#tableau1+1; # on récupère le nombre de mots que contient le patron

	 @adjCTNA = split(/\//,$tableau1[$#tableau1]); # recuperation de l'adjectif
	 @etiadjCTNA = split(/:/,$adjCTNA[1]); # recuperation de l'etiquette pour l'adjectif

          #if ( $etiadjCTNA[0] =~ /PAR/ )
	  #{
	  #    $EtiAdj = "PPE" ;
	  #}
	  #else
	  #{
	  #    $EtiAdj = "ADJ" ;
	  #}

	 #PremierDernier($c, $t, $struct, $type, $EtiAdj); # enregistrement du patron trouvé
	 PremierDernier($c, $t, $struct, $type); # enregistrement du patron trouvé

	 # Recherche de l'indice du 1er COO de la chaine : permet de savoir à partir de quel mot la relance de
	 # recherche de patrons va etre effectuée 
	 $i = 0;
	 while( ! (($tableau1[$i]." ") =~ /$COO/) && ($i < $t)) 
	 {
 	    $i = $i+1;
	    $taille = $i;      
	 }

	 # Construction de la sous-chaine (tous les mots situés après le 1er COO) sur laquelle on va relancer des recherches de patrons 
	 $lignecoord = $tableau1[$taille+1];
	 for ($j=$taille+2;$j<$t;$j++) 
	 {
	    $lignecoord = $lignecoord." ".$tableau1[$j];
	 }

	 # Recherche de patrons (Modifications et Bases) dans la sous-chaine
	 ExtraitModif($lignecoord);

	 # Le pointeur va se positionner sur le mot suivant le 1er COO
	 @tab = split(/ /,$pointeur,$taille+2);

	 $pointeur = $tab[$taille+1];

       last SWITCH;
       }


       # RECHERCHE DE COORDINATION DE TETE DE TYPE "npn"

       if($machaine =~ /^ ($COORDTETENPN)(.*)$/)
       {
	 $c=$1;    	    # récupération du patron trouvé dans $c
	 $type="COORDTETE";
	 $struct="npn";
	 @tableau1 = split(/ /,$c); # stockage de tous les mots du patron dans un tableau
	 $t = $#tableau1+1; # on récupère le nombre de mots que contient le patron

	 #PremierDernier($c, $t, $struct, $type, ""); # enregistrement du patron trouvé
	 PremierDernier($c, $t, $struct, $type); # enregistrement du patron trouvé

	 # Recherche de l'indice du 1er COO de la chaine : permet de savoir à partir de quel mot la relance de
	 # recherches de patrons va etre effectuée 
	 $i = 0;
	 while( ! (($tableau1[$i]." ") =~ /$COO/) && ($i < $t)) 
	 {
	    $i = $i+1;
	    $taille = $i; 
	 }

	 # Construction de la sous-chaine (tous les mots situés après le 1er COO) sur laquelle on va relancer des recherches de patrons 
	 $lignecoord = $tableau1[$taille+1];
	 for ($j=$taille+2;$j<$t;$j++) 
	 {
	    $lignecoord = $lignecoord." ".$tableau1[$j];
	 }

	 # Recherche de patrons (Modifications et Bases) dans la sous-chaine
	 ExtraitModif($lignecoord);

	 # Le pointeur va se positionner sur le mot suivant le 1er COO
	 @tab = split(/ /,$pointeur,$taille+2);

	 $pointeur = $tab[$taille+1];

	 last SWITCH;
       }



       # ELIMINATION DES CAS OU L'ON NE TOMBE PAS SUR UN NOM : le pointeur passe directement au mot suivant
       if($machaine !~ /^ ($NOM)(.*)$/)   
       {
	    @tab = split(/ /,$pointeur,2);
	    $pointeur = $tab[1];

	    last SWITCH;
       }



       # RECHERCHE D'ENUMERATION DE TYPE "na"

       if($machaine =~ /^ ($ENUMNA)(.*)$/)   
       {
	 $c=$1;    	    # récupération du patron trouvé dans $c
	 $type="ENUM"; 
	 $struct="na";
	 @tableau1 = split(/ /,$c); # stockage de tous les mots du patron dans un tableau
	 $t = $#tableau1+1; # on récupère le nombre de mots que contient le patron

	 @adjCTNA = split(/\//,$tableau1[$#tableau1]); # recuperation de l'adjectif
	 @etiadjCTNA = split(/:/,$adjCTNA[1]); # recuperation de l'etiquette pour l'adjectif

          #if ( $etiadjCTNA[0] =~ /PAR/ )
	  #{
	  #    $EtiAdj = "PPE" ;
	  #}
	  #else
	  #{
	  #    $EtiAdj = "ADJ" ;
	  #}

	 #PremierDernier($c, $t, $struct, $type, $EtiAdj); # enregistrement du patron trouvé
	 PremierDernier($c, $t, $struct, $type ); # enregistrement du patron trouvé

	 $i = 0;
	 # Recherche de la taille de la sous-chaine sur laquelle on va relancer des recherches de patrons 
	 # (récupération de la taille du tableau jusqu'au dernier COO)
	 while( ! (($tableau1[$i]." ") =~ /$VIRG/) && ($i < $#tableau1)) 
	 {
	    $i = $i+1;
	    $taille = $i;
	 }

	 # Construction de la sous-chaine sur laquelle on va relancer des recherches de patrons
	 $ligneenum = $tableau1[0];
	 for ($j=1;$j<$taille;$j++) 
	 {
	    $ligneenum = $ligneenum." ".$tableau1[$j];
	 }

	 # Recherche de patrons (Modifications et Bases) dans la sous-chaine
	 ExtraitModif($ligneenum);

	 # Le pointeur va se positionner sur le mot suivant le  dernier mot du patron trouvé
	 @tab = split(/ /,$pointeur,$t+1);
	 $pointeur = $tab[$t];

	 last SWITCH;
       }


       # RECHERCHE D'ENUMERATION DE TYPE "npn"

       if($machaine =~ /^ ($ENUMNPN)(.*)$/)   
       {
	 $c=$1;    	    # récupération du patron trouvé dans $c
	 $type="ENUM";
	 $struct="npn";
	 @tableau1 = split(/ /,$c); # stockage de tous les mots du patron dans un tableau
	 $t = $#tableau1+1; # on récupère le nombre de mots que contient le patron

	 #PremierDernier($c, $t, $struct, $type, ""); # enregistrement du patron trouvé
	 PremierDernier($c, $t, $struct, $type ); # enregistrement du patron trouvé

	 # Recherche de la taille de la sous-chaine sur laquelle on va relancer des recherches de patrons 
	 # (récupération de la taille du tableau jusqu'a la derniere virgule)
	 $i = 0;
	 while( ! (($tableau1[$i]." ") =~ /$VIRG/) && ($i < $#tableau1))
	 {
	    $i = $i+1;
	    $taille = $i;   
	 }

	 # Construction de la sous-chaine sur laquelle on va relancer des recherches de patrons
	 $ligneenum = $tableau1[0];
	 for ($j=1;$j<$taille;$j++) 
	 {
	   $ligneenum = $ligneenum." ".$tableau1[$j];    
	 }

	 # Recherche de patrons (Modifications et Bases) dans la sous-chaine
	 ExtraitModif($ligneenum);

	 # Le pointeur va se positionner sur le premier mot suivant le COO:
	 # Recherche de l'indice du 1er COO de la chaine
	 $i = 0;
	 while( ! (($tableau1[$i]." ") =~ /$COO/) && ($i < $t)) 
	 {
	    $i = $i+1;
	    $taille = $i; 
	 }

	 @tab = split(/ /,$pointeur,$taille+2);
	 $pointeur = $tab[$taille+1];

	 last SWITCH;
       } 



       # RECHERCHE DE COORDINATION DE TYPE "na"

       if($machaine =~ /^ ($COORDNA)(.*)$/)   
       {
	 $c=$1;    	    # récupération du patron trouvé dans $c
	 $type="COORD"; 
	 $struct="na";
	 @tableau1 = split(/ /,$c); # stockage de tous les mots du patron dans un tableau
	 $t = $#tableau1+1; # on récupère le nombre de mots que contient le patron

	 @adjCTNA = split(/\//,$tableau1[$#tableau1]); # recuperation de l'adjectif
	 @etiadjCTNA = split(/:/,$adjCTNA[1]); # recuperation de l'etiquette pour l'adjectif

          #if ( $etiadjCTNA[0] =~ /PAR/ )
	  #{
	  #    $EtiAdj = "PPE" ;
	  #}
	  #else
	  #{
	  #    $EtiAdj = "ADJ" ;
	  #}


	 #PremierDernier($c, $t, $struct, $type, $EtiAdj); # enregistrement du patron trouvé
	 PremierDernier($c, $t, $struct, $type ); # enregistrement du patron trouvé

	 $i = $#tableau1;
	 # Recherche de la taille de la sous-chaine sur laquelle on va relancer des recherches de patrons 
	 # (récupération de la taille du tableau jusqu'au dernier COO)
	 while( ! (($tableau1[$i]." ") =~ /$COO/) && ($i > 0)) 
	 {
	    $i = $i-1;
	    $taille = $i;
	 }

	 # Construction de la sous-chaine sur laquelle on va relancer des recherches de patrons
	 $lignecoord = $tableau1[0];
	 for ($j=1;$j<$taille;$j++) 
	 {
	    $lignecoord = $lignecoord." ".$tableau1[$j];
	 }

	 # Recherche de patrons (Modifications et Bases) dans la sous-chaine
	 ExtraitModif($lignecoord);

	 # Le pointeur va se positionner sur le premier mot suivant le patron trouvé
	 @tab = split(/ /,$pointeur,$t+1);
	 $pointeur = $tab[$t];

	 last SWITCH;
       }


       # RECHERCHE DE COORDINATION DE TYPE "npn"

       if($machaine =~ /^ ($COORDNPN)(.*)$/)   
       {
	 $c=$1;    	    # récupération du patron trouvé dans $c
	 $type="COORD";
	 $struct="npn";
	 @tableau1 = split(/ /,$c); # stockage de tous les mots du patron dans un tableau
	 $t = $#tableau1+1; # on récupère le nombre de mots que contient le patron

	 #PremierDernier($c, $t, $struct, $type, ""); # enregistrement du patron trouvé
	 PremierDernier($c, $t, $struct, $type); # enregistrement du patron trouvé

	 # Recherche de la taille de la sous-chaine sur laquelle on va relancer des recherches de patrons 
	 # (récupération de la taille du tableau jusqu'au dernier COO)
	 $i = $#tableau1;
	 while( ! (($tableau1[$i]." ") =~ /$COO/) && ($i > 0))
	 {
	    $i = $i-1;
	    $taille = $i;   
	 }

	 # Construction de la sous-chaine sur laquelle on va relancer des recherches de patrons
	 $lignecoord = $tableau1[0];
	 for ($j=1;$j<$taille;$j++) 
	 {
	   $lignecoord = $lignecoord." ".$tableau1[$j];    
	 }

	 # Recherche de patrons (Modifications et Bases) dans la sous-chaine
	 ExtraitModif($lignecoord);

	 # Le pointeur va se positionner sur le premier mot suivant le COO:
	 @tab = split(/ /,$pointeur,$taille+2);
	 $pointeur = $tab[$taille+1];

	 last SWITCH;
       } 



       # RECHERCHE DE COORDINATION DE TYPE "npna"

       if($machaine =~ /^ ($COORDNPNA)(.*)$/)   
       {
	 $c=$1;    	    # récupération du patron trouvé dans $c
	 $type="COORD";
	 $struct="npna";
	 @tableau1 = split(/ /,$c); # stockage de tous les mots du patron dans un tableau
	 $t = $#tableau1+1; # on récupère le nombre de mots que contient le patron

	 #PremierDernier($c, $t, $struct, $type, ""); # enregistrement du patron trouvé
	 PremierDernier($c, $t, $struct, $type); # enregistrement du patron trouvé

	 # Recherche de la taille de la sous-chaine sur laquelle on va relancer des recherches de patrons 
	 # (récupération de la taille du tableau jusqu'au dernier COO)
	 $i = $#tableau1;
	 while( ! (($tableau1[$i]." ") =~ /$COO/) && ($i > 0))
	 {
	    $i = $i-1;
	    $taille = $i;   
	 }

	 # Construction de la sous-chaine sur laquelle on va relancer des recherches de patrons
	 $lignecoord = $tableau1[0];
	 for ($j=1;$j<$taille;$j++) 
	 {
	    $lignecoord = $lignecoord." ".$tableau1[$j];    
	 }

	 # Recherche de patrons (Modifications et Bases) dans la sous-chaine
	 ExtraitModif($lignecoord);

	 # Le pointeur va se positionner sur le mot suivant le patron:
	 @tab = split(/ /,$pointeur,$t+1);
	 $pointeur = $tab[$t];

	 last SWITCH;
       } 




       # RECHERCHE D'ATTIBUT DE TYPE "na"

       if ($machaine =~ /^ ($ATTRNA)(.*)$/)
       {
	 $c=$1;    	    # récupération du patron trouvé dans $c
	 $type="ATTR";
	 $struct="na";
	 @tableau1 = split(/ /,$c); # stockage de tous les mots du patron dans un tableau
	 $t = $#tableau1+1; # on récupère le nombre de mots que contient le patron


	 @nomNVA = split(/\//,$tableau1[0]); # recuperation du nom
	 @adjderNVA = split(/\//,$tableau1[$#tableau1]);  # recuperation de l'adjectif en attribut

	 @etinomNVA = split(/:/,$nomNVA[1]); # recuperation de l'etiquette du nom
	 @etiadjderNVA = split(/:/,$adjderNVA[1]); # recuperation de l'etiquette de l'adjectif en attribut 
	 my $etiAdj = "" ;     # récupération de l'étiquette de l'adjectif PPE ou ADJ

	 # Recherche de la position du verbe
	 $pos = 0;
	 while( ! (($tableau1[$pos]." ") =~ /$AUXI/) && ($pos < $#tableau1))
	 {
	    $pos = $pos+1;
	 }

	 @verbeNVA = split(/\//,$tableau1[$pos]); # recuperation du verbe
	 @etiverbeNVA = split(/:/,$verbeNVA[1]); # recuperation de l'etiquette du verbe

          #if ( $etinomNVA[0] =~ /PAR/ )
	  #{
	  #    $etiAdj = "PPE" ;
	  #}
	  #else
	  #{
	  #    $etiAdj = "ADJ" ;
	  #}


	 if (! ( (($etinomNVA[1] eq "m") && ($etiadjderNVA[1] eq "f")) ||
		 (($etinomNVA[1] eq "f") && ($etiadjderNVA[1] eq "m")) ||
		 (($etinomNVA[2] eq "s") && ($etiadjderNVA[2] eq "p")) ||
		 (($etinomNVA[2] eq "p") && ($etiadjderNVA[2] eq "s")) ||
		 (($etinomNVA[2] eq "s") && ($etiverbeNVA[2] eq "p")) ||
		 (($etinomNVA[2] eq "p") && ($etiverbeNVA[2] eq "s")) )  )
	 {
	    #PremierDernier($c, $t, $struct, $type, $etiAdj); # enregistrement du patron trouvé
	    PremierDernier($c, $t, $struct, $type ); # enregistrement du patron trouvé
	 }


	 # Recherche de la taille de la sous-chaine sur laquelle on va relancer des recherches de patrons 
	 # (récupération de la taille du tableau jusqu'au verbe etre)
	 $i = 0;
	 while( ! (($tableau1[$i]." ") =~ /$AUXI/) && ($i < $#tableau1))
	 {
	    $i = $i+1;
	    $taille = $i;   
	 }

	 # Construction de la sous-chaine sur laquelle on va relancer des recherches de patrons
	 $ligneattr = $tableau1[0];
	 for ($j=1;$j<$taille;$j++) 
	 {
	     $ligneattr = $ligneattr." ".$tableau1[$j];    
	 }

	 # Recherche de patrons (Modifications et Bases) dans la sous-chaine
	 ExtraitModif($ligneattr);

	 # Le pointeur va se positionner sur le mot suivant le patron:
	 @tab = split(/ /,$pointeur,2);
	 $pointeur = $tab[1];

	 last SWITCH;
       }



       # RECHERCHE D'ATTRIBUT DE TYPE "npna"

       if ($machaine =~ /^ ($ATTRNPNA)(.*)$/)
       {
	 $c=$1;    	    # récupération du patron trouvé dans $c
	 $type="ATTR";
	 $struct="npna";
	 @tableau1 = split(/ /,$c); # stockage de tous les mots du patron dans un tableau
	 $t = $#tableau1+1; # on récupère le nombre de mots que contient le patron


	 @nomNVA = split(/\//,$tableau1[0]); # recuperation du nom
	 @adjderNVA = split(/\//,$tableau1[$#tableau1]);  # recuperation de l'adjectif en attribut

	 @etinomNVA = split(/:/,$nomNVA[1]); # recuperation de l'etiquette du nom
	 @etiadjderNVA = split(/:/,$adjderNVA[1]); # recuperation de l'etiquette de l'adjectif en attribut 

	 # Recherche de la position du verbe
	 $pos = 0;
	 while( ! (($tableau1[$pos]." ") =~ /$AUXI/) && ($pos < $#tableau1))
	 {
	    $pos = $pos+1;
	 }

	 @verbeNVA = split(/\//,$tableau1[$pos]); # recuperation du verbe
	 @etiverbeNVA = split(/:/,$verbeNVA[1]); # recuperation de l'etiquette du verbe

	 if (! ( (($etinomNVA[1] eq "m") && ($etiadjderNVA[1] eq "f")) ||
		 (($etinomNVA[1] eq "f") && ($etiadjderNVA[1] eq "m")) ||
		 (($etinomNVA[2] eq "s") && ($etiadjderNVA[2] eq "p")) ||
		 (($etinomNVA[2] eq "p") && ($etiadjderNVA[2] eq "s")) ||
		 (($etinomNVA[2] eq "s") && ($etiverbeNVA[2] eq "p")) ||
		 (($etinomNVA[2] eq "p") && ($etiverbeNVA[2] eq "s")) )  )
	 {
	    #PremierDernier($c, $t, $struct, $type, ""); # enregistrement du patron trouvé
	    PremierDernier($c, $t, $struct, $type ); # enregistrement du patron trouvé
	 }


	 # Recherche de la taille de la sous-chaine sur laquelle on va relancer des recherches de patrons 
	 # (récupération de la taille du tableau jusqu'au verbe etre)
	 $i = 0;
	 while( ! (($tableau1[$i]." ") =~ /$AUXI/) && ($i <$#tableau1 ))
	 {
	    $i = $i+1;
	    $taille = $i;   
	 }

	 # Construction de la sous-chaine sur laquelle on va relancer des recherches de patrons
	 $ligneattr = $tableau1[0];
	 for ( $j=1; $j<$taille; $j++ ) 
	 {
	    $ligneattr = $ligneattr." ".$tableau1[$j];    
	 }

	 # Recherche de patrons (Modifications et Bases) dans la sous-chaine
	 ExtraitModif($ligneattr);

	 # Le pointeur va se positionner sur le mot suivant le patron:
	 @tab = split(/ /,$pointeur,$t+1);
	 $pointeur = $tab[$t];

	 last SWITCH;
       }



       # RECHERCHE DE MODIFICATION DE TYPE "na"

       if ($machaine =~ /^ ($MODIFNA)(.*)$/)
       {
	 $t = traiteModifNA($1);

	 # Le pointeur va se positionner sur le premier mot suivant le patron
	 @tab = split(/ /,$pointeur,$t+1);
	 $pointeur = $tab[$t];

	 last SWITCH;
       }


       # RECHERCHE DE MODIFICATION DE TYPE "npna"

       if ($machaine =~ /^ ($MODIFNPNA)(.*)$/)
       {
	 $t = traiteModifNPNA($1);

	 # Le pointeur va se positionner sur le mot suivant le patron trouvé

	 @tab = split(/ /,$pointeur,$t+1);
	 $pointeur = $tab[$t];

	 last SWITCH;
       }




       # RECHERCHE DE MODIFICATION DE TYPE "npn"

       if ($machaine =~ /^ ($MODIFNPN)(.*)$/)
       {
	 $t = traiteModifNPN($1);

	 # Le pointeur va se positionner apres le dernier adjectif du patron trouvé
	 # Recherche de la taille de la sous-chaine sur laquelle on va relancer des recherches de patrons 
	 # (récupération de la taille du tableau jusqu'au dernier ADJP)
	 $i = $#tableau1;
	 while( ! (($tableau1[$i]." ") =~ /$ADJP/) && ($i > 0))
	 {
	    $i = $i-1;
	    $taille = $i;   
	 }

	 @tab = split(/ /,$pointeur,$taille+2);
	 $pointeur = $tab[$taille+1];

	 last SWITCH;
       }




       # RECHERCHE DE BASE DE TYPE "na"

       if($machaine =~ /^ ($BASENA)(.*)$/)            
       {
	 $t = traiteBase($1,"na");

	 # Le pointeur va se positionner sur le  mot suivant le patron
	 @tab = split(/ /,$pointeur,$t+1);
	 $pointeur = $tab[$t];

	 last SWITCH;
       } # fin if


       # RECHERCHE DE BASE DE TYPE "npna"

       if($machaine =~ /^ ($BASENPNA)(.*)$/)
       {
	 $t = traiteBase($1,"npna");

	 # Le pointeur va se positionner sur le mot suivant le patron	     
	 @tab = split(/ /,$pointeur,5);
	 $pointeur = $tab[4];

	 last SWITCH;
       } # fin if


       # RECHERCHE DE BASE DE TYPE "npnpn"

       if($machaine =~ /^ ($BASENPNPNG)(.*)$/)
       {
	 $t = traiteBase($1,"npnpn");

	 # Le pointeur va se positionner sur le dernier lemme du patron
	 @tab = split(/ /,$pointeur,5);
	 $pointeur = $tab[4];

	 last SWITCH;
       } # fin if


       # RECHERCHE DE BASE DE TYPE "npnn"

       if($machaine =~ /^ ($BASENPNN)(.*)$/)
       {
	 $t = traiteBase($1,"npnn");

	 # Le pointeur va se positionner sur le mot suivant le patron	     
	 @tab = split(/ /,$pointeur,5);
	 $pointeur = $tab[4];

	 last SWITCH;
       } # fin if




       # RECHERCHE DE BASE DE TYPE "npnng" (AVEC GUILLEMETS)

       if($machaine =~ /^ ($BASENPNNG)(.*)$/)
       {
	 $t = traiteBase($1,"npnng");

	 # Le pointeur va se positionner sur le mot suivant le patron	     
	 @tab = split(/ /,$pointeur,7);
	 $pointeur = $tab[6];

	 last SWITCH;
       } # fin if



       # RECHERCHE DE BASE DE TYPE "npn"

       if($machaine =~ /^ ($BASENPN)(.*)$/)
       {
	 $t = traiteBase($1,"npn");

	 # Le pointeur va se positionner sur le deuxieme mot du patron	     
	 @tab = split(/ /,$pointeur,2);
	 $pointeur = $tab[1];

	 last SWITCH;
       } # fin if




       # RECHERCHE DE BASE DE TYPE "nv"

       if($machaine =~ /^ ($BASENV)(.*)$/)
       {
	 $t = traiteBase($1,"nv");

	 # Le pointeur va se positionner sur le  mot suivant le patron
	 @tab = split(/ /,$pointeur,$t+1);
	 $pointeur = $tab[$t];

	 last SWITCH;
       } # fin if



       # PAS DE BASE NI DE MODIFICATION NI DE COORDONNATION NI D'ENUMERATION TROUVEES : le pointeur passe au mot suivant

	 @tab = split(/ /,$pointeur,2);
	 $pointeur = $tab[1];

       } # fin du switch

     } # fin du while

} # fin du foreach(<FIC2>)  

close(FIC2);


##############################################
# recherche des regroupements morphologiques 
###############################################

print "Analyse morphologique\n\n";
print "CAS1\n";
morph_casun();
print "CAS2\n";
morph_casdeux();
print "CAS3\n";
morph_castrois();

print "Ecriture du fichier de sortie \n\n";

# on recupere la frequence totale des patrons
$N = $Deb{'nb'};

print "Recherche adjectif relationnel et prefixe premier et dernier lemme \n\n";
# pour chaque lemme "lemmedeb" apparaissant en debut de patron
for $lemmedeb( keys %Deb )
{
    next if ($lemmedeb eq 'nb');

    # on recupere la frequence des patrons commencant par ce lemme "lemmedeb"
    $freqDeb = $Deb{$lemmedeb}{'nb'};


    #pour chaque lemme de fin
    for $lemmefin ( keys %{ $Deb{$lemmedeb} } )
    {
	next if ($lemmefin eq 'nb');
	next if ($lemmefin eq 'sommeLog');
	next if ($lemmefin eq 'struct');

	# on recupere la frequence des patrons commencant par ce lemme "lemmedeb"
	$freqFin = $Fin{$lemmefin}{'nb'};

	#genere temp.txt
	sortie_temp_txt($lemmedeb, $lemmefin, $freqDeb, $freqFin);
    } 
}

#ecriture de la frequence totale
print SORTIE $N,"\n";

#ecriture des adj relationnel
for $adj( keys %AdjRel)
{
    print SORTIE3 $adj," ",1," ( )\n";
}     

print "Fin\n\n";	   


close(SORTIE);
close(SORTIE2);
close(SORTIE3);
close(SORTIE4);
close(SORTIE5); 
close(SORTIE6);
close(SORTIE7);
close(SORTIE8);



#################################################################################
# FONCTIONS D'ANALYSES MORPHOLOGIQUE
#
#
################################################################################





##################################################
# CAS 2 (derivation sur deuxieme lemme)           #
##################################################
#sub Prefixe_derlem
sub morph_casdeux
{
    my $premierLemme ; #Dernier lemme du tableau Fin
    my $dernierLemme ; #Premier lemme du tableau Fin
    my $newMot ; # valeur du nouveau mot construit
    my $i ; #variable de boucle 

    # on recupere le premier et le dernier lemme 

    #pour chaque dernier Lemme
    foreach $dernierLemme( keys %Fin )
    {
	next if ($dernierLemme eq 'nb');

	#pour chaque transformation
	foreach my $transform (keys %CAS2)
	{	
	    my $syntax=$CAS2{$transform}->[0];
	    my $pat=$CAS2{$transform}->[1];
	    my $affect=$CAS2{$transform}->[2];
	    my $listregles=$CAS2{$transform}->[3];
	    my $exception=$CAS2{$transform}->[4];
	    my $FILE=$CAS2{$transform}->[5];
	    my ($pat3, $affect2, $affixe, $newaffixe);
	    
	    #pour chaque regle
	    for (my $i=0 ; $i <= $#$listregles ; $i++)
	    {
		
		$affixe=$listregles->[$i]->[0];
		$newaffixe=$listregles->[$i]->[1];

		
		$pat3=$pat;
		$pat3=~ s/_AFFIXE_/$affixe/;
		$pat3=~ s/_NEWAFFIXE_/$newaffixe/;
		
		next if ($dernierLemme !~ /$pat3/);
		
		my @valtemp=($1, $2, $3);
		$affect2=$affect;
		$affect2=~ s/_V1_/$valtemp[0]/;
		$affect2=~ s/_V2_/$valtemp[1]/;
		$affect2=~ s/_V3_/$valtemp[2]/;
		$affect2=~ s/_AFFIXE_/$affixe/;
		$affect2=~ s/_NEWAFFIXE_/$newaffixe/;
		
		$newMot=$affect2;
		next if($newMot eq "");

		#pour chaque premier lemme
		foreach $premierLemme ( keys %{$Fin{$dernierLemme}} )
		{
		    next  if( ($Deb{$premierLemme}{'struct'} & $syntax) != $syntax);

		    if (exists $Deb{$premierLemme}{$newMot} && (!defined($exception) || !exists($exception{$affixe}{$dernierLemme})))
		    {
			$AdjRel{$dernierLemme} = $newMot if($transform =~ /adjrel/); #sauve les adj relationnels
			print $FILE $Deb{$premierLemme}{$dernierLemme}{'id'}, " ", $premierLemme," ",$dernierLemme," --- ", $Deb{$premierLemme}{$newMot}{'id'}, " ", $premierLemme," ",$newMot,"\n";
		    }
		}
	    }
	}
    }
}

##################################################
# CAS 1 (derivation sur premier lemme)           #
##################################################

#sub Prefixe_premlem
sub morph_casun
{
    my $premierLemme ; #Dernier lemme du tableau Fin
    my $dernierLemme ; #Premier lemme du tableau Fin
    my $newMot ; # valeur du nouveau mot construit
    my $i ; #variable de boucle 

    # on recupere le premier et le dernier lemme 

    #pour chaque premier Lemme
    foreach $premierLemme( keys %Deb )
    {
	next if ($premierLemme eq 'nb');

	#pour chaque transformation
	foreach my $transform (keys %CAS1)
	{
	    my $syntax=$CAS1{$transform}->[0];
	    next  if( ($Deb{$premierLemme}{'struct'} & $syntax) != $syntax);

	    my $pat=$CAS1{$transform}->[1];
	    my $affect=$CAS1{$transform}->[2];
	    my $listregles=$CAS1{$transform}->[3];
	    my $exception=$CAS2{$transform}->[4];
	    my $FILE=$CAS1{$transform}->[5];
	    my ($pat3, $affect2, $affixe, $newaffixe);
	    
	    #pour chaque regle
	    for (my $i=0 ; $i <= $#$listregles ; $i++)
	    {
		
		$affixe=$listregles->[$i]->[0];
		$newaffixe=$listregles->[$i]->[1];
		
		$pat3=$pat;
		$pat3=~ s/_AFFIXE_/$affixe/;
		$pat3=~ s/_NEWAFFIXE_/$newaffixe/;
		
		next if ($premierLemme !~ /$pat3/);
		
		my @valtemp=($1, $2, $3);
		$affect2=$affect;
		$affect2=~ s/_V1_/$valtemp[0]/;
		$affect2=~ s/_V2_/$valtemp[1]/;
		$affect2=~ s/_V3_/$valtemp[2]/;
		$affect2=~ s/_AFFIXE_/$affixe/;
		$affect2=~ s/_NEWAFFIXE_/$newaffixe/;
		
		$newMot=$affect2;
		next if($newMot eq "");
	

		#pour chaque dernier lemme
		foreach $dernierLemme ( keys %{ $Deb{$premierLemme} } )
		{

		    if( exists($Fin{$dernierLemme}{$newMot}) && (!defined($exception) ||!exists($exception{$affixe}{$premierLemme})) )
		    {
			print $FILE $Deb{$premierLemme}{$dernierLemme}{'id'}, " ", $premierLemme," ",$dernierLemme," --- ", $Fin{$dernierLemme}{$newMot}{'id'}, " ", $newMot," ",$dernierLemme,"\n";
		    }
		}
	    }
	}
    }
}
                               

#######################################################################################
# Fonction qui relie deux couples avec inversion + dérivation morphologique           #
# CAS 3 (croisement)                                                                               #
#######################################################################################

#sub Inversion
sub morph_castrois

{
  #Déclaration des variables utilisées dans Prefixe
    my $premierLemme ; #Premier lemme du tableau Deb
    my $dernierLemme ; #Dernier lemme du tableau Deb
    my $newMot ;
    
    #pour chaque premier Lemme
    foreach $premierLemme( keys %Deb )
    {
	next if ($premierLemme eq 'nb');


	#pour chaque transformation
	foreach my $transform (keys %CAS3)
	{
	    my $syntax=$CAS3{$transform}->[0];
	    next  if( ($Deb{$premierLemme}{'struct'} & $syntax) != $syntax);


	    my $pat=$CAS3{$transform}->[1];
	    my $affect=$CAS3{$transform}->[2];
	    my $listregles=$CAS3{$transform}->[3];
	    my $exception=$CAS2{$transform}->[4];
	    my $FILE=$CAS3{$transform}->[5];
	    my ($pat3, $affect2, $affixe, $newaffixe);
	    
	    #Generation du ppé
	    #pour chaque regle
	    for (my $i=0 ; $i <= $#$listregles ; $i++)
	    {
		
		$affixe=$listregles->[$i]->[0];
		$newaffixe=$listregles->[$i]->[1];
		
		$pat3=$pat;
		$pat3=~ s/_AFFIXE_/$affixe/;
		$pat3=~ s/_NEWAFFIXE_/$newaffixe/;
		
		next if ($premierLemme !~ /$pat3/);
		
		my @valtemp=($1, $2, $3);
		$affect2=$affect;
		$affect2=~ s/_V1_/$valtemp[0]/;
		$affect2=~ s/_V2_/$valtemp[1]/;
		$affect2=~ s/_V3_/$valtemp[2]/;
		$affect2=~ s/_AFFIXE_/$affixe/;
		$affect2=~ s/_NEWAFFIXE_/$newaffixe/;
		
		$newMot=$affect2;
		next if($newMot eq "");

		#pour chaque dernier lemme
		foreach $dernierLemme ( keys %{ $Deb{$premierLemme} } )
		{

		    next if ( (!exists $Deb{$dernierLemme}) ||
			      ( ( ($Deb{$dernierLemme}{'struct'} & 1) != 1) && # na
				( ($Deb{$dernierLemme}{'struct'} & 4) != 4) ) # npna
			      );
		    if ( 
			 (exists $Deb{$dernierLemme}{$newMot}) && (!defined($exception) || !exists($exception{$affixe}{$premierLemme})) &&
			 (($Deb{$dernierLemme}{$newMot}{'struct'} & 1) == 1)
			 )
		    {
			print $FILE $Deb{$premierLemme}{$dernierLemme}{'id'}, " ", $premierLemme," ",$dernierLemme," --- ", $Deb{$dernierLemme}{$newMot}{'id'}, " ", $dernierLemme," ",$newMot,"\n";
		    }
		}
	    }
	}
    }
}
#######################################################################################
# Fonction qui genere le fichier temp.txt                                             #
#######################################################################################
# Paramètres :                                                                        #   
#  $_[0] : premier lemme                                                              #
#  $_[1] : dernier lemme                                                              #
#  $_[2] : frequence du premier lemme                                                            #
#  $_[3] : frequence du dernier lemme                                                              #
#######################################################################################
                               
sub sortie_temp_txt
{
    my $freqDebFin;
    my $lemmePatron;
    my $freq;


    # on recupere le 1er lemme du tableau Deb
    my $lemmedeb = $_[0];  # premier lemme 
    my $lemmefin = $_[1];  # dernier lemme 
    my $freqDeb = $_[2]; # frequence premier lemme
    my $freqFin = $_[3]; # frequence dernier lemme


    # on initialise la frequence des patrons commencant par "lemmedeb" et finissant par "lemmefin" 
    $freqDebFin = $Deb{$lemmedeb}{$lemmefin}{'nb'};


    print SORTIE $Deb{$lemmedeb}{$lemmefin}{'id'};
    my $st=int($Deb{$lemmedeb}{$lemmefin}{'struct'});
    
    # on affiche la frequence des patrons commencant par "lemmedeb" et finissant par "lemmefin"
    print SORTIE " ", $freqDebFin," ", $freqDeb, " ", $freqFin, " ", $lemmedeb," ",$lemmefin," ", $st, " ";

    # pour chaque patron commencant par "lemmedeb" et finissant par "lemmefin" 
    for $lemmePatron ( keys %{ $Deb{$lemmedeb}{$lemmefin} } )
    {
	next if ($lemmePatron eq 'nb');
	next if($lemmePatron eq 'struct');
	next if ($lemmePatron eq 'id');
	
	# on recupere la frequence du patron
	$freq = $Deb{$lemmedeb}{$lemmefin}{$lemmePatron}[0];

	#pour afficher un message en cas d'erreur
	if ($freq == 0)
	{
	    print "probleme avec : ",$lemmedeb." ".$lemmefin." ".$lemmePatron;
	}

	print SORTIE "* ";
	
	# on affiche le lemme pour chaque mot du patron
	print SORTIE $lemmePatron," ";

    }
    
    print SORTIE "\n";
}
