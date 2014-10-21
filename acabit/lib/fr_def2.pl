############################################################################  
#                                                                           #
# Fichiers de définition des variations morphologiques                      #
#                                                                           #
#############################################################################  

##########DERNIERE MISE A JOUR 27/10/04








##################################################################
# DEFINITION DES REGLES
# CAS 1 : variation sur lemme1
# CAS 2 : variation sur lemme2
# CAS 3 : variation croisée
#
# FORMAT: CONDITION_SYNTAXIQUE, 'PATTERN DE DECOUPAGE', 'TRANSFORMATION A EFFECTUER', Tableau Regles, EXCEPTIONS,  FICHIER DE SORTIE
#
# CONDITION SYNTAXIQUE : masque de bit :   na 1 ; npn 2 ; npna 4 ; nv 8 ; nn 16 ; npnpn 32 ; npnn, npnng 64;
# PATTERN DE DECOUPAGE : expression régulière permettant de séparer l'affique du radical
# TRANSFORMATION A EFFECTUER : affection du nouveau lemme à partir des donnée obtenues dans la pattern de découpage
# TABLEAU DE REGLES : liste de couple ("affixe", "newaffixe"). Si il n'y a pas de règles, utiliser le tableau @NULL
# EXCEPTIONS : table de hachage des exception indexé sur les affixes
# FICHIERS DE SORTIE : Poignee du fichier de sortie
#
#
# VARIABLES: _AFFIXE_ : affixe à la base de la règle
#            _NEWAFFIXE_ : affixe de remplacement ds la règle
#            _V1_ : correspond au $1 de l'expression régulière
#            _V2_ : correspond au $2 de l'expression régulière
#            _V3_ : correspond au $3 de l'expression régulière
############################################################



%CAS1= (
	prefixe => [0, '^(_AFFIXE_)-?(.+)$', '_V2_', \@TPrefixe , 0, SORTIE6 ],
	tiret => [0, '^(.+)-(.+)$', '_V1__V2_', \@NULL , 0, SORTIE5 ],
	suffens => [0, '^(.+)(_AFFIXE_)$', '_V1__NEWAFFIXE_', \@TSuffEns , %EXCEPTION_SUFF_ENS, SORTIE8 ],
	suffs1 => [0, '^(.*)(_AFFIXE_)$', '_V1__NEWAFFIXE_', \@TSuffS1 , 0, SORTIE9 ]
    );

%CAS2= (
	prefixe => [0, '^(_AFFIXE_)-?(.+)$', '_V2_', \@TPrefixe , \%EXEPTION_PREF, SORTIE6 ],
	tiret => [0, '^(.+)-(.+)$', '_V1__V2_', \@NULL , 0, SORTIE5 ],
	adjrel_ique1 => [1, '^(.*)é([trndplmbvgfh])ique$', '_V1_e_V2_', \@NULL , 0, SORTIE4 ],
	adjrel_ique2 => [1, '^(.*)é([trndplmbvgfh])ique$', '_V1_è_V2_e', \@NULL , 0, SORTIE4 ],
	adjrel => [1, '^(.*)(_AFFIXE_)$', '_V1__NEWAFFIXE_', \@TMorphAdjRel ,0 , SORTIE4 ],
	);

%CAS3= (
	suffinv => [2, '^(..+)(_AFFIXE_)$', '_V1__NEWAFFIXE_', \@TSuffInv , 0, SORTIE7 ]
	);


#########################################"
# TABLEAU DE REGLE 
# chaque règle est sous la forme [_AFFIXE_, _NEWAFFIXE_ ]

#REGLE NULL (pas de règle)
@NULL = (["",""]);



# tableau contenant les variations morphologiques
# pour chaque suffixe d'adjectif en premier champ, le tableau fournit
# le suffixe de nom equivalent en deuxieme champ 


@TMorphAdjRel = (
#ique
    ["ématique","ème"],
    ["étrique","ètre"],
    ["tifique","ce"],
    ["otique","ose"],          #hypnotique/hypnose
    ["inique","en"],
    ["atique","e"],         # suffixe en "ique"
    ["atique","a"],         
    ["ytique","se"],         #analytique/analyse
    ["élique","ile"],
    ["cique","x"],
    ["tique",""], 
    ["ique",""],
    ["ique","ie"],
    ["ique","e"],            #dictionnaire/dictionnairique
    ["ique","a"],
    ["ique","i"],
    ["ique","é"],
    ["ique","as"],
    ["ique","os"],          #tétanique/tétanos
    ["ique","ose"],          #métamorphique/métamorphose
    ["ique","us"],              #tonique/tonus
    ["ique","icité"],
    ["ique","isme"],
#aire
    ["ulmonaire","oumon"], 
    ["ulaire","le"],        # muscle/musculaire
    ["étaire","ète"],
    ["laire",""],           # suffixe en "aire"
    ["laire","e"],
    ["iaire","e"],
    ["naire",""],
    ["naire","in"],
    ["aire",""],
    ["aire","e"],
    ["aire","é"],         #volontaire/volonté
    ["aire","ation"],
#al
    ["oronal","ouronne"],
    ["estial","ête"],
    ["arial","aire"],   	# salaire/salarial  
    ["dical","decine"],   	# médical/médecine 
    ["ital","et"],          
    ["inal","en"],
    ["inal",""],   		# nominal/nom 
    ["ical","ex"],
    ["ocal","oix"],          
    ["oral","eur"],     #floral/fleur     
    ["acal","e"],          
    ["asal","ez"],          
    ["yal","i"],
    ["ial","e"],          # province/provincial
    ["cal","que"],
    ["al","e"],
    ["al",""],
    ["al","um"],        #rectal/rectum
    ["al","us"],        #viral/virus
#eux
    ["oureux","eur"],          
    ["uleux","le"],          
    ["ileux","oil"],    #pileux/poil
    ["ieux","ion"],
    ["ieux","e"],
    ["eux","e"],
    ["eux",""],
#oire
    ["oire","ion"],
#é    
    ["boré", "bre"],
    ["iégé", "iège"],
    ["ulé", "le"],
    ["é","us"],           #cactée/cactus
    ["é", "e"],
    ["é", "ure"],
#cole
    ["cole","culture"],
#er
    ["égulier", "ègle"],
    ["estier", "êt"],       #forêt/forestier
    ["ier","e"],            #bourse/boursier
    ["ier",""],
    ["er","e"],
#ien
    ["idien","is"],     #rachidien/rachis
    ["orien","oire"],
    ["ien","ie"],
    ["ien","is"],       #pubien/pubis
    ["ien",""],          #Balzac/balzacien
#ain
    ["orain","oire"],
#el
    ["iel","ie"],
    ["el","ité"],   #eternel/eternité
    ["el","e"],		#culture/culturel
    ["el",""],
#in
    ["arin","er"],
    ["alin","el"],
    ["guin","g"],
    ["lin",""],
    ["in","us"],               #utérin/utérus
    ["in",""],
#if
    ["ursif","ours"],
    ["if",""],
    ["if","ion"],
    ) ; 



#PREFIXE
@TPrefixe = ( 
["agro",""], ["anté",""], ["anti",""], ["archi",""], ["auto",""], ["arrière",""], ["avant",""], ["bi",""], ["bio",""], ["co",""], ["contre",""], ["de",""], ["dé",""], ["di",""], ["épi",""], ["extra",""], ["hémi",""], ["hyper",""], ["hypo",""], ["il",""], ["im",""], ["in",""], ["infra",""], ["inter",""], ["ir",""], ["macro",""], ["méta",""], ["micro",""], ["mini",""], ["mono",""], ["multi",""], ["néo",""], ["non",""], ["para",""], ["péri",""], ["post",""], ["pré",""], ["pro",""], ["pseudo",""], ["quasi",""], ["re",""], ["ré",""], ["rétro",""], ["sans",""], ["semi",""], ["sous",""], ["sub",""], ["super",""], ["supra",""],  ["sur",""], ["télé",""], ["trans",""], ["tri",""], ["ultra",""]) ;

#Nom typique du 1er actant : transport/transporteur


@TSuffS1 = (
#eur
    ["eur",""],
    ["eur","e"],
#ier
    ["ier",""],
    ["ier","e"],
#er
    ["er",""],
    ["er","e"],
    ) ; 

#SUFFENS
@TSuffEns = (
#ade
    ["ade","e"],
    ["ade",""],
#age
    ["lage",""],
    ["osage","ôt"],
    ["nage",""],
    ["gage","gue"],   #langage/langue
    ["age","e"],
    ["age",""],
#erie
    ["esterie","êt"], #foresterie/forêt
    ["nnerie","n"],
    ["erie","e"],
    ["erie",""]
    ) ; 


#Traitement morphologique des inversions refletant "action de V"


@TSuffInv = (
    #ade
    ["ade","er"],
    #age
    ["ièreté","ier"],   #grossier/grossièreté
    ["arté","air"],   #clair/clarté
    ["ité","e"],      #stupide/stupidité
    ["ité",""],
    ["té",""],  #beau/beauté
    #erie
    ["erie","er"],
    ["erie","e"],
    #ence
    ["ence","ent"],  #transparent/transparence
    #esse
    ["ssesse","s"],  #bas/bassesse
    ["esse","e"],  #vite/vitesse
    #eur
    ["sseur","s"],  #gros/grosseur
    ["eur",""],  #lent/lenteur
    #ise
    ["ise","e"], #bête/bêtise
    #ure
    ["ure",""], #droit/droiture
    ["ure","er"],
    #ion
    ["ion",""], #correct/correction
    #age
    ["issage","ir"],
    ["age","er"],
    #ation
    ["ification",""],
    ["isation",""],
    ["ation","er"],
    #ement
    ["chissement","c"],
    ["issement","ir"],
    ["nement","ner"]
    ) ; 


