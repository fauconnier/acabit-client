#############################################################################  
#                                                                           #
# Fichiers des définitions des exceptions                                   #
#                                                                           #
#############################################################################  

##########DERNIERE MISE A JOUR 27/10/04

$MOT = "[a-zA-Zàâéèêùûôçïî\'\-_]+";  

$EXCEPTION_QUANT = "($MOT\/SBC:(_|m|f):(_|s|p)\/(plupart|multitude|partie|peu|quantité|majorité|foule|nombre|masse))"; 

$EXCEPTION_PREP = "($MOT\/SBC:(_|m|f):(_|s|p)\/(terme|sein|but|moyen|vue|cas|place|charge|voie|lieu|environ|fin|niveau|base|fonction))"; 

# exceptions prefixe
%EXCEPTION_PREF = 
    (
     "de" => \%EXCEPTION_PREF_DE,
     "dé" => \%EXCEPTION_PREF_DEAIGU,
     "trans" => \%EXCEPTION_PREF_TRANS,
     "re" => \%EXCEPTION_PREF_RE,
     "ré" => \%EXCEPTION_PREF_REAIGU,
     "sur" => \%EXCEPTION_PREF_SUR,
     "im" => \%EXCEPTION_PREF_IM,
     "in" => \%EXCEPTION_PREF_IN,
     "inter" => \%EXCEPTION_PREF_INTER,
     "hypo" => \%EXCEPTION_PREF_HYPO,
     "para" => \%EXCEPTION_PREF_PARA,
     "pro" => \%EXCEPTION_PREF_PRO,
     "pré" => \%EXCEPTION_PREF_PREAIGU
     );

# exceptions suffixe
%EXCEPTION_SUFF_ENS= 
    (
     "age" => \%EXCEPTION_SUFF_ENS_AGE
     );


%EXCEPTION_SUFF_ENS_AGE=
    (
     "paysage" => "pays"
     );


%EXCEPTION_PREF_DE=();
%EXCEPTION_PREF_DEAIGU=
    (
     "décomposition" => "composition",
     "déformation" => "formation"
     );

%EXCEPTION_PREF_TRANS=
    (
     "transformation"=>"formation"
     );

%EXCEPTION_PREF_RE=
    (
     "reconnaissance"=>"connaissance",
     "refraction"=>"fraction",
     "représentation"=>"présentation",
     "reproduction"=>"production",
     "revue"=>"vue"
     );

%EXCEPTION_PREF_REAIGU=
    (
     "réaction"=>"action",
     "réactivité"=>"activité",
     "réflexion"=>"flexion",
     "résolution"=>"solution"
     );


%EXCEPTION_PREF_SUR=
    (
     "surface"=>"face"
     );

%EXCEPTION_PREF_IN=
    (
     "information"=>"formation"
     );

%EXCEPTION_PREF_INTER=
    (
     "interface"=>"face",
     "intersection"=>"section"
     );

%EXCEPTION_PREF_PARA=
    (
     "paragraphe"=>"graphe",
     "paraphrase"=>"phrase",
     "parasite"=>"site"
     );

%EXCEPTION_PREF_PRO=
  (
     "proposition"=>"position",
     "proposer"=>"poser"
     );

%EXCEPTION_PREF_PREAIGU=
  (
     "préposition"=>"position"
     );

%EXCEPTION_PREF_IM=
    (
     "imposer"=>"poser"
     );

%EXCEPTION_PREF_HYPO=
    (
     "hypothèse"=>"thèse"
     );
