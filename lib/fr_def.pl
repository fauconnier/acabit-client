############################################################################  
#                                                                           #
# Fichiers des définitions                                                  #
#                                                                           #
#############################################################################  

##########DERNIERE MISE A JOUR 27/10/04

$DATE = "[0-9][0-9]\/[^\/]+\/[0-9][0-9]";
$SEP = "\-\/\-";
#$REF = "[0-9][0-9][0-9][0-9][0-9][0-9][0-9]\/CAR\/[0-9][0-9][0-9][0-9][0-9][0-9][0-9]";
$REF = "[^\/]+\/[^\/]+\/[^\/^<]+";

$TITRE = "\<TI\>";  
$TEXTE = "\<AB\>";  
$PHRASE = "\<ph_nb=[0-9]+\>";
$FINPHRASE = "\<\/ph\>";  
  
$MOT = "[a-zA-Zàâéèêùûôçïî\'\-_]+";  
$INFOS = "[ a-zA-Zàâéèêùûôçïî\'\-_«»]+";

$CHRS = "[:,;\.\?!«»]";  
$TAG = "[A-Z][A-Z][A-Z]+";  
$GENRE = "[fm\_]";  
$NB = "[sp\_]";  

   

$COO = "(et|ou)\/COO\/(et|ou) ";  
$VIRG =  ",\/, ";  
$GUIL_OUV =  "«\/« ";  
$GUIL_FERM =  "»\/» ";  


#ETIQUETTES
$ADJ_ETIQUET="ADJ";
$NOM_ETIQUET="SBC";
$ADV_ETIQUET="ADV";
$PREP_ETIQUET="PREP";
$DTN_ETIQUET="DTN";
$DTC_ETIQUET="DTC";

#######
$NOM = "($MOT\/SBC:$GENRE:$NB\/$MOT )|($MOT\/SBP\/$MOT )";  

$NOMP = "($MOT\/SBC:$GENRE:p\/$MOT )";  
 
$NOMPART = "($MOT)\/SBC:$GENRE:$NB\/(type|chair|phase|genre|origine|état|couleur|pâte|voie|face) "; 


$NOMVIDE =  "($MOT)\/SBC:$GENRE:$NB\/effet ";

$ADV = "($MOT\/ADV\/$MOT )";

$ADJ = "($MOT\/ADJ:$GENRE:$NB\/$MOT )";   
  
$PPE = "($MOT\/ADJ[12]PAR:$GENRE:$NB\/$MOT )";  
$PPE2 = "($MOT\/ADJ2PAR:$GENRE:$NB\/$MOT )";  

  
  # Insertion d'adjectif ou d'adverbe dans le groupe adjectivel  
$ADJP = "($ADJ)|($PPE)"; 
$ADJPV = "($ADV)*($ADJP)";
$ADJP2 = "($ADJ)|($PPE2)"; # adjectifs sauf ADJ1PAR initeressants en attribut
$ADJP2V = "(($COO)?$ADV)*($ADJP2)";
 
$COOADJ = "($COO)($ADJPV)";     
  


$ENTRE = "entre\/PREP\/entre ";

$PREP_D = "d[e\']\/PREP\/d[e\'] ";  
$PREP_A = "à\/PREP\/à ";  
$PREP_SUR = "sur\/PREP\/sur ";   
$PREPDETOTH = "(dans|sous|avant|après|chez)\/PREP\/(dans|sous|avant|après|chez) ";  
$PREPOTH = "(en|pour|par)\/PREP\/(en|pour|par) ";  
  
$DET_DEFS = "(l[e\'a])\/DTN:$GENRE:s\/le ";  
$DET_DEFP = "les\/DTN:$GENRE:p\/le ";  
$DET_UNDEFS = "(un[e]?)\/DTN:$GENRE:s\/un ";  

$DET_DCONTP = "des\/DTC:_:p\/du ";
$DET_ACONTP = "aux\/DTC:_:p\/au ";
$DET_DCONTS = "du\/DTC:m:s\/du ";  
$DET_ACONTS = "au\/DTC:m:s\/au ";
$DET_CONT = "(($DET_DCONTP)|($DET_DCONTS)|($DET_ACONTP)|($DET_ACONTS))";  
 
$D_DDEFS = "((($PREP_D)($DET_DEFS))|($DET_DCONTS))";  
$D_DUNDEFS = "($PREP_D)($DET_UNDEFS)";  
$A_DDEFS = "((($PREP_A)($DET_DEFS))|($DET_ACONTS))";  
$A_DUNDEFS = "($PREP_A)($DET_UNDEFS)";  
$SUR_DDEFS = "($PREP_SUR)($DET_DEFS)";  
$SUR_DUNDEFS = "($PREP_SUR)($DET_UNDEFS)";  
$SUR_DETP = "($PREP_SUR)(($DET_DEFP)|(DET_DCONTP))";  
$O_DDEFS = "($PREPDETOTH)($DET_DEFS)";  
$O_DUNDEFS = "($PREPDETOTH)($DET_UNDEFS)";  
$O_DETP = "($PREPDETOTH)(($DET_DEFP)|($DET_DCONTP))";  

$PREP_DSP = "(($D_DDEFS)|($DET_DCONTP))";
$PREP_ASP = "(($A_DDEFS)|($DET_ACONTP))";

$PREP =  "($PREP_D)|($PREP_A)|($PREP_SUR)|($PREPOTH)";  
$PREPDDEFS = "(($D_DDEFS)|($A_DDEFS)|($O_DDEFS)|($SUR_DDEFS))";  
$PREPDUNDEFS = "($D_DUNDEFS)|($A_DUNDEFS)|($O_DUNDEFS)|($SUR_DUNDEFS)";  
$PREPDETP = "($O_DETP)|($SUR_DETP)|($DET_DCONTP)|($DET_ACONTP)";  
   
$DGNS = "($DET_DEFS)($NOM)";  
$DGNP = "($DET_DEFP)($NOM)";  
$CGNS = "($D_DDEFS)($NOM)";  
$CGNP = "($DET_DCONTP)($NOM)"; 



$PP_ETRE = "été\/EPAR:m:s\/être ";
$FETRE = "(est|sont|était|fut|furent|sera|seront|serait|seraient)\/VCJ:[123]p:$NB:(fut|pst|ps|impft):(ind|cond)\/être:3g ";  
$IMP_ETRE = "\{étaient\/VCJ:3p:p:pst:\{ind\|subj\}\/étayer:1g\|étaient\/VCJ:3p:p:impft:ind\/être:3g\} ";  
$FAVOIR = "(a|ont|avait|avaient|eut|eurent|aura|auront|aurait|auraient)\/VCJ:[123]p:$NB:(fut|pst|ps|impft):(ind|cond)\/avoir:3g ";  
$INF_ETRE = "être\/ENCFF\/être ";  
$INF_AVOIR = "avoir\/ANCFF\/avoir ";  
$PPE_AVOIR = "eu\/APAR:$GENRE:$NB\/avoir ";  
$VAVOIRA = "($FAVOIR)";                   # |($INF_AVOIR)|($PPE_AVOIR))";  
$VETREA = "(($FETRE)|($IMP_ETRE))";       #  |($INF_ETRE)
$VETREP = "($VAVOIRA)($ADV)*($PP_ETRE)";

$VETRE = "(($VETREA)|($VETREP))";

$AUXI = "(($VETREA)|($VAVOIRA))";

$VINF = "($MOT\/VNCFF\/$MOT )";  




# STRUCTURES DE BASE
   
  # Structure de base : NaVinf   
$B001 = "($NOM)($PREP_A)($VINF)";  

  
  # Structure de base : Nadj - Variantes d'insertion     
$B002 = "($NOM)($ADJP)";


  # Structure de base : NN   
$B003 = "($NOM)($NOM)";          

  
  # Structure de base : NPN - Variantes flexionnelles  
$B004 = "($NOM)($PREP)($NOM)";                          
$B008 = "($NOM)($ENTRE)($NOMP)";                          

  
  # Structure de base : NPDN - Variantes flexionnelles 
$B005 = "($NOM)($PREPDDEFS)($NOM)";
$B006 = "($NOM)($PREPDETP)($NOM)";    
$B007 = "($NOM)($PREPDUNDEFS)($NOM)"; 


# Structure de base : NP{type, genre, phase, etc} A
  
$B009="($NOM)($PREP)($NOMPART)($ADJP)";  

# Structure de base : NP{type, genre, phase, etc} (prep) N
  
$B010="($NOM)($PREP)($NOMPART)($NOM)";
$B011="($NOM)($PREP)($NOMPART)($GUIL_OUV)($NOM)($GUIL_FERM)";
$B012="($NOM)($PREP_A)($NOMVIDE)($PREP_D)($NOM)";  





# MISE EN ATTRIBUT
# avec pour structure de base : NA
  
$A001 = "($NOM)($ADJPV)*($VETRE)($ADJP2V)";               
 
# avec pour structure de base : NPNA
  
$A002 = "($NOM)($ADJPV)*($VETRE)($ADJPV)*($PREP)($NOMPART)($ADJP2)";               




# MODIFICATIONS

#  Modifications avec pour structure de base : NA
$M001 = "($NOM)($ADJPV)($ADJPV)+";  
$M002 = "($NOM)($ADV)+($ADJP)";  


#  Modifications avec pour structure de base : NPN
$M003 = "($NOM)($ADJPV)+($PREP)($NOM)";
$M004 = "($NOM)($ADJPV)+($PREPDDEFS)($NOM)";     
$M005 = "($NOM)($ADJPV)+($PREPDETP)($NOM)";      
$M006 = "($NOM)($ADJPV)+($PREPDUNDEFS)($NOM)"; 


#  Modifications avec pour structure de base : NPNA
$M007 = "($NOM)($ADJPV)+($PREP)($NOMPART)($ADJP)";  




#   COORDINATIONS
  
#   Coordinations avec structure de base : NA 
$C001 = "($NOM)($ADJPV)+($COOADJ)";  

 
#   Coordinations avec structure de base : NPN   
$C002 = "($NOM)($ADJPV)*($PREP_D)($NOM)($COO)($PREP_D)($NOM)";     
$C003 = "($NOM)($ADJPV)*($PREP_A)($NOM)($COO)($PREP_A)($NOM)";    


#   Coordination avec structure de base NPDN  
$C004 = "($NOM)($ADJPV)*($PREP_DSP)($NOM)($COO)($PREP_DSP)($NOM)";  
$C005 = "($NOM)($ADJPV)*($PREP_ASP)($NOM)($COO)($PREP_ASP)($NOM)";  


#   Coordination avec structure de base NPNA  
$C006 = "($NOM)($ADJPV)*($PREP)($NOMPART)($ADJP)($COO)($PREP)($NOMPART)($ADJP)";  




#   COORDINATIONS DE TETE 
 
#  Coordinations de tete avec pour structure de base : NA  
$CT01 = "($DGNS)($COO)($DGNS)($ADJP)";  
$CT02 = "($DGNP)($COO)($DGNP)($ADJP)";  
$CT03 = "($CGNS)($COO)($CGNS)($ADJP)";  
$CT04 = "($CGNP)($COO)($CGNP)($ADJP)"; 
 
#  Coordinations de tete avec pour structure de base : NPN
$CT05 = "($DGNS)($COO)($DGNS)($PREP_D)($NOM)";  
$CT06 = "($DGNP)($COO)($DGNP)($PREP_D)($NOM)";  
$CT07 = "($CGNS)($COO)($CGNS)($PREP_D)($NOM)";  
$CT08 = "($CGNP)($COO)($CGNP)($PREP_D)($NOM)";  




#    ENUMERATIONS
  
#    Enumeration des A a partir de NA
$E001 = "($NOM)($ADJPV)+(($VIRG)($ADJPV))+($COOADJ)";   
  
 
#    Enumeration des PN a partir de NPN
$E002 = "($NOM)($ADJPV)*($PREP_D)($NOM)(($VIRG)($PREP_D)($NOM))+($COO)($PREP_D)($NOM)";  
$E003 = "($NOM)($ADJPV)*($PREP_A)($NOM)(($VIRG)($PREP_A)($NOM))+($COO)($PREP_A)($NOM)";  
  
#    Enumeration des PDN a partir de NPDN
$E004 = "($NOM)($ADJPV)*(PREP_DSP)($NOM)(($VIRG)($PREP_DSP)($NOM))+($COO)(PREP_DSP)($NOM)";
$E005 = "($NOM)($ADJPV)*(PREP_ASP)($NOM)(($VIRG)($PREP_ASP)($NOM))+($COO)(PREP_ASP)($NOM)";




# EXPRESSIONS REGULIERES FINALES

# base
$BASENV = "($B001)";
$BASENA = "($B002)";
$BASENPN = "(($B003)|($B004)|($B005)|($B006)|($B007)|($B008))";
$BASENPNA = "($B009)";
$BASENPNN = "($B010)";
$BASENPNNG = "($B011)";
$BASENPNPNG = "($B012)";

#attribut
$ATTRNA = "($A001)";
$ATTRNPNA = "($A002)";

# modification
$MODIFNA = "(($M001)|($M002))";
$MODIFNPN = "(($M003)|($M004)|($M005)|($M006))";
$MODIFNPNA = "($M007)";

#coordination
$COORDNA = "($C001)";
$COORDNPN = "($C002)|($C003)|($C004)|($C005)";
$COORDNPNA = "($C006)";

#coordination de tete
$COORDTETENA = "(($CT01)|($CT02)|($CT03)|($CT04))";
$COORDTETENPN = "(($CT05)|($CT06)|($CT07)|($CT08))";
    #$COORDTETENPNA = "($CT09)";

#enumeration
$ENUMNA = "($E001)";
$ENUMNPN = "($E002)|($E003)|($E004)|($E005)";






