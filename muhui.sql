 /* #######################---SGBD PROJECT---########################*/

--Entreprise: Supermachine
--Créé par:Muhui YU, Shuying YE
--Supermachine est une entreprise qui vent des appareils électrique, 

/* ########################---PARTIE 1 Table---#############################################################################*/
/*
Initialiser tous les tables.
*/
--Editeur:Muhui YU
drop table produit cascade constraints;
drop table devis cascade constraints;
drop table vente cascade constraints;
drop table commande cascade constraints;
drop table entrepot cascade constraints;
drop table livraison_reussi cascade constraints;
drop table information cascade constraints;

/*$$$$$$$$$$$$$$$$$$$$$ Table Produit $$$$$$$$$$$$$$$$$$$$$$$*/
--Cet tableau comporte les information de produit dans notre entreprise.
--Editeur:Muhui YU
create table produit(
refArt integer,
nom varchar2(20) not null,
prix_unit number(20,2) not null,
stock integer not null,
description varchar2(20),
constraint pk_produit primary key(refArt),
constraint check_produit_prix_unit check(prix_unit>0),
constraint check_produit_stock check(stock>=0),
constraint check_produit_unique unique(refArt,nom)
);

/*$$$$$$$$$$$$$$$$$$$$$ Table Devis $$$$$$$$$$$$$$$$$$$$$$$*/
--Cet tableau comporte le histoire de l'acheteur appelle le procédure demande_devis()
--Editeur:Muhui YU
create table devis(
refDevis integer,
refArt integer,
nom_prod varchar2(20) not null,
quantite_achat integer not null,
prix_total number(20,2) not null,
date_devis date not null,
constraint pk_devis primary key (refDevis),
constraint fk_devis_refArt foreign key(refArt) references produit(refArt),
constraint check_devis_quantite_achat check(quantite_achat>0)
);

	
/*$$$$$$$$$$$$$$$$$$$$$ Table Vente $$$$$$$$$$$$$$$$$$$$$$$*/
--Cet tableau comporte les information du achat que l'acheteur fait dans SuperMachine.
--Editeur:Muhui YU
create table vente(
idv integer,
refDevis integer,
siret_acheteur varchar2(14) not null, 
siret_ban_ach varchar2(14) not null,
cle varchar2(255) not null,
etat varchar2(10) not null,
date_vente date not null,
constraint pk_vente primary key (idv),
constraint fk_vente_refDevis foreign key(refDevis) references devis(refDevis)
);
	
/*$$$$$$$$$$$$$$$$$$$$$ Table commande $$$$$$$$$$$$$$$$$$$$$$$*/
--Cet tableau pour noter les achats que SuperMachine a fait
--Editeur:Muhui YU
create table commande(
idc integer,
loginVendeur varchar2(14) not null, 
cle_autorisation varchar2(255) not null, 
refDevis integer not null,
constraint pk_commande primary key (idc)
);
	
/*$$$$$$$$$$$$$$$$$$$$$ Table Entrepôt $$$$$$$$$$$$$$$$$$$$$$$*/
--Cet tableau pour noter les marchandise que SuperMachine a reçu
--Editeur:Muhui YU
create table entrepot(
ide integer,
loginVendeur varchar2(20),
siret_vendeur varchar2(14) not null, 
nom_prod varchar2(20) not null, 
refArt integer not null,
quantite integer not null,
prixTTC number(20,2) not null,
constraint pk_entrepot primary key (ide)
);

	
/*$$$$$$$$$$$$$$$$$$$$$ Table Livraison_reussi $$$$$$$$$$$$$$$$$$$$$$$*/
--Cet tableau pour noter les marchandise que SuperMachine a envoyé à l'acheteur
--Editeur:Muhui YU
create table livraison_reussi(
idl integer,
loginAcheteur varchar2(20),
refDevis integer,
nom_prod varchar2(20) not null, 
quantite integer not null,
prixHT number(20,2) not null,
date_livraison date not null,
constraint pk_livraison primary key (idl),
constraint fk_livraison_refDevis foreign key(refDevis) references devis(refDevis)
);

/*$$$$$$$$$$$$$$$$$$$$$ Table Information $$$$$$$$$$$$$$$$$$$$$$$*/
--Cet tableau pour noter les informations de CCI,banque,notre entreprise
--Editeur:Muhui YU
create table information(
idin integer,
nom varchar2(20) not null,
loginOracle varchar2(20) not null,
siret number(14),
compte integer,
constraint pk_information primary key (idin)
);

insert into information values (seq_idin.nextval,'entreprise','myu_a','10000000000110','');
insert into information values (seq_idin.nextval,'banque','ngiovin_a','10000000000102','68');
insert into information values (seq_idin.nextval,'cci','qrichar_a','','');

--Banque 1:alaawad_a   siret:10000000000161 compte:1212
--Banque 1:ngiovin_a   siret:10000000000102 compte:68
--update information set compte='68' where nom='banque';

--sequence pour tous les tableaux
drop sequence seq_refArt;
create sequence seq_refArt start with 6600;
drop sequence seq_refDevis;
create sequence seq_refDevis start with 9900;
drop sequence seq_idv;
create sequence seq_idv start with 1;
drop sequence seq_idc;
create sequence seq_idc start with 1;
drop sequence seq_ide;
create sequence seq_ide start with 1;
drop sequence seq_idl;
create sequence seq_idl start with 1;
drop sequence seq_idin;
create sequence seq_idin start with 1;


INSERT INTO produit VALUES (seq_refArt.nextval,'appleIpod', 45, 30,'');
INSERT INTO produit VALUES (seq_refArt.nextval,'appleNano', 61,50,'');
INSERT INTO produit VALUES (seq_refArt.nextval,'AsusTablet', 288,25,'');
INSERT INTO produit VALUES (seq_refArt.nextval,'HTCPhone', 410,5,'');
INSERT INTO produit VALUES (seq_refArt.nextval,'IpadMini', 201,10,'');


	
/* #####################---PARTIE 2 procédure et function---#############################################################################*/
/*
--2.1
--nom de ce procédure: demande_devis
--utilisateur: acheteur(les autre entreprise et CCI)
--fonction: pour l'achateur consulte la situation et le devis des produit.
--explication:l'achateur appelle demande_devis pour confirmer le produit que il veut acheter est disponible.
            si oui , demande_devis va retourner les valeurs pour la procédure prochaine--achat()
--Editeur:Muhui YU
*/

create or replace procedure Demande_devis(
  refArtVendeur in varchar2,
  quantite in integer)
is
	cursor r is
    select refArt from produit;
	fini_recherche integer;
	quantite_livrable integer;
	nomc varchar2(20);
	prix_unitc integer;
	prix_total integer;
	non_produit exception;
	produit_epuise exception;
	produit_insuffit exception;
	begin
	    dbms_output.put_line('******************************************');
		dbms_output.put_line('******************************************');
		dbms_output.put_line('Bienvenue chez SuperMachine!');
		dbms_output.put_line('Siret de notre entreprise est 10000000000110!');
		dbms_output.put_line('******************************************');
		dbms_output.put_line('******************************************');
    /* si l'entrepise n'a pas ce produit*/	
		fini_recherche:=0;	
		for x in r loop
    		if x.refArt=refArtVendeur
			then fini_recherche:=1;
			end if;
  		end loop;
		if fini_recherche=0
			then raise non_produit;
		else 
    /* si l'entrepise a ce produit */
			select stock into quantite_livrable from produit where refArt=refArtVendeur;
			if quantite_livrable=0
				then raise produit_epuise;		
			elsif (quantite_livrable<quantite)
				then raise produit_insuffit;
			else
        /* Ce devis est reçu. Insérer les valeur dans le table devis */
				select nom,prix_unit into nomc,prix_unitc from produit where refArt=refArtVendeur;
				prix_total:=prix_unitc*quantite;
				insert into devis values(seq_refDevis.nextval,refArtVendeur,nomc,quantite,prix_total,sysdate);
				dbms_output.put_line('refDevis = '||seq_refDevis.currval);
				dbms_output.put_line('refArtVendeur = '||refArtVendeur);
				dbms_output.put_line('quantite_livrable = '||quantite);
				dbms_output.put_line('prix_unitTTC = '||prix_unitc);
				dbms_output.put_line('prix_totalTTC = '||prix_total);
			end if;
		end if;
	exception
		when non_produit then dbms_output.put_line('Supermachine ne vend pas ce produit: refArtVendeur = '||refArtVendeur);
		when produit_epuise then dbms_output.put_line('Ce produit: refArtVendeur = '||refArtVendeur||' chez Supemachine est epuise maintenant.');
		when produit_insuffit then dbms_output.put_line('SuperMachine a pas assez de quantite pour votre commande. La quantite disponiblece des produit: refArtVendeur = '||refArtVendeur||' est: '||quantite);
	end;
/
show error;
grant execute on Demande_devis to public;

/*
--2.2
--nom de la procédure: Achat
--utilisateur: acheteur(les autre entreprises et CCI)
--fonction: faire une commande et appeler la procédure Paie(). si la banque a bien reçu les valeurs, on va exécuter 
            la procédure livraison().
--Editeur:Muhui YU
*/
create or replace function Achat(
SiretAcheteur in varchar2,
SiretBanqueAcheteur in varchar2,
cle_autorisation in varchar2,
refDevisAcheteur in integer)
return integer
is
    cursor r is
	select refDevis from devis;
	cursor r1 is
	select idv from vente where refDevis=refDevisAcheteur;
	fini_recherche integer;
	prix_totalv number(20,2);
	siretVendeur varchar2(14);
	refArtVendeur integer;
	nomArtile varchar2(20);
	quantite integer;
	paiement varchar2(255);
	livraison varchar2(255);
	loginAcheteur varchar2(20);
	loginCCI varchar2(20);
	resultat integer;
	loginBanque varchar2(20);
	description varchar2(255);
	login varchar2(255);
	idvente integer;
	begin
	fini_recherche:=0;	
		for x in r loop
    		if x.refDevis=refDevisAcheteur
			then fini_recherche:=1;
			end if;
  		end loop;
		if fini_recherche=0
			then dbms_output.put_line('Supermachine ne trouve pas ce devis qui refDevis = '||refDevisAcheteur);
			return 0;
		else 
        /* si l'entrepise a ce devis */
			select refArt,nom_prod,quantite_achat,prix_total into refArtVendeur,nomArtile,quantite,prix_totalv from devis where refDevis=refDevisAcheteur;
			/* si l'acheteur a deja fait la meme commande ou non. */
			open r1;
            fetch r1 into idvente;
			/* si c'est une nouvelle commande. on donne un nouveau record dans le tableau vente*/
            if r1%notfound then 
            insert into vente values(seq_idv.nextval,refDevisAcheteur,SiretAcheteur,SiretBanqueAcheteur,cle_autorisation,'pas_paie',sysdate);
			close r1;
			idvente:=seq_idv.currval;
			end if;
			select siret into siretVendeur from information where nom='entreprise';
			select loginOracle into loginBanque from information where nom='banque';
			paiement := 'begin :1 :='||loginBanque||'.paie(:2,:3,:4,:5,:6,:7); end;'; 
            execute immediate paiement using out resultat, in SiretAcheteur,in SiretBanqueAcheteur,in siretVendeur,in cle_autorisation,in prix_totalv,in description;
			  if resultat=0
			    then dbms_output.put_line('Desole!Votre paiement ne est pas reussi!**SuperMachine**');
				return resultat;
			  else
			  /* si le paiement d'acheteur a bien recu. */
			    update vente set etat='deja_paie' where idv=idvente;
				update vente set cle=cle_autorisation where idv=idvente;
			    dbms_output.put_line('Votre paiement a bien recu. Merci!**SuperMachine**');
				select loginOracle into loginCCI from information where nom='cci';
                login := 'begin :1 :='||loginCCI||'.loginParSiret(:2); end;'; 
                execute immediate login using out loginAcheteur, in SiretAcheteur;
				livraison := 'begin '|| loginAcheteur ||'.livraison(:1,:2,:3,:4,:5); end;'; 
                execute immediate livraison using in siretVendeur,in nomArtile,in refArtVendeur,in quantite,in prix_totalv;
				dbms_output.put_line('Merci de votre commande. SuperMachine a fait la livraison.**SuperMachine**');
				update produit set stock=stock-quantite where refArt=refArtVendeur;
				prix_totalv:=prix_totalv*(1-0.196);
                insert into livraison_reussi values(seq_idl.nextval,loginAcheteur,refDevisAcheteur,nomArtile,quantite,prix_totalv,sysdate);
                return 1;
               end if;
        end if;
end;
/
show error;
grant execute on Achat to public;


/*
--2.3
--nom de la procédure: livraison
--utilisateur: vendeuse
--fonction: donner les marchandises à l'acheteur.
--Editeur:Muhui YU 
*/
create or replace procedure livraison(
siretVendeur in number,
nomArtile in varchar2,
refArtVendeur in integer,
quantite in integer,
prixTTC in number)
is
loginVendeur varchar2(20);
loginCCI varchar2(20);
login varchar2(255);
begin
select loginOracle into loginCCI from information where nom='cci';
login := 'begin :1 := '||loginCCI||'.loginParSiret(:2); end;'; 
execute immediate login using out loginVendeur, in siretVendeur;
insert into entrepot values (seq_ide.nextval,loginVendeur,siretVendeur,nomArtile,refArtVendeur,quantite,prixTTC);
dbms_output.put_line('SuperMachine a bien recu votre marchandise. Merci!');
end;
/
show error;
grant execute on livraison to public;
--execute myu_a.livraison(10000000000106,'IPHONE4S',100502,1,300);

--2.4
--nom de la procédure: toutLesProduit
--fonction: donner le liste de tout les produit dans l'entreprise.
--Editeur:Shuying YE

create or replace procedure ToutLesProduit
is
cursor c is
select refArt,nom,prix_unit,stock from produit order by refArt;
begin
for x in c loop
dbms_output.put_line('num du produit:'||x.refArt||', nom du produit: '||x.nom||', prix: '||x.prix_unit||', stock: '||x.stock);
end loop;
end;
/
grant execute on ToutLesProduit to public;


--2.5
--Explication:listeFonctionsEntreprise() indiquent les fonctions et procédure que peuvent utiliser les autres chez eux.
--Editeur:Shuying YE 
create or replace procedure listeFonctionsEntreprise
is
begin
	dbms_output.put_line('*******************SuperMachine***********************');
	dbms_output.put_line('Tout les fonctions de nous:');
	dbms_output.put_line('1--Procedure Demande_devis(refArtVendeur varchar2,quantite integer)');
	dbms_output.put_line('Achateur utilise cette procédure, elle affiche les informations suivant:');
	dbms_output.put_line('--refDevis INT,');
	dbms_output.put_line('--refArtVendeur INT');
	dbms_output.put_line('--quantite_livrable INT');
	dbms_output.put_line('--prix_unitTTC NUMBER(20,2)');
	dbms_output.put_line('--prix_totalTTC NUMBER(20,2)');
	dbms_output.put_line('====================================================');
	dbms_output.put_line('2--Function Achat(SiretAcheteur varchar2(255),SiretBanqueAcheteur varchar2(255),cle_autorisation varchar2(255),refDevisAcheteur integer)');
	dbms_output.put_line('Achateur utilise cette function, elle retoune int:');
	dbms_output.put_line('--0 si échouer, 1 si réussir');
	dbms_output.put_line('====================================================');
	dbms_output.put_line('3--Procedure livraison(Siretvendeur number,nomArtile varchar2,refArtVendeur integer,quantite integer,prixTTC number)');
	dbms_output.put_line('vendeuse utilise cette procédure pour donner la marchandise à SuperMachine.');
	dbms_output.put_line('====================================================');
	dbms_output.put_line('4--Procedure ToutLesProduit()');
	dbms_output.put_line('Achateur utilise cette procédure pour consulter tout les produit chez SuperMachine');
	dbms_output.put_line('********************************************************');
end;
/
grant execute on listeFonctionsEntreprise to public;




/* ########################---PARTIE 3 process comme un acheteur---####################################################################*/


/*-------Afficher la liste de toutes les Entreprises et les produits---------------*/
--set serveroutput on;
--execute qrichar_a.consulterEntreprise;

/*------------appeler la function demande_devis() en vendeuse----------------------*/

--execute loginVendeuse.demande_devis(refArtVendeur INT, quantite INT);
--execute ttroilo_a.demande_devis(100,1);
--execute zzhai_a.demande_devis(100501,1);


/*------------------------creer cle_autorisation en banque-------------------------*/
--appeler la function creerAutorisation en banque pour obtenir cle_autorisation
--Editeur:Muhui YU 
create or replace procedure creerAutorisation(siretVendeur number)
is
  loginBanque varchar2(20);
  cle varchar2(255);
  resultat varchar2(255);
begin
  select loginOracle into loginBanque from information where nom='banque';
  cle:='begin :1:='||loginBanque||'.creerAutorisation('||siretVendeur||');end;';
  execute immediate cle using out resultat;
  dbms_output.put_line('cle_autorisation est: '||resultat);
end;
/
show error;
--execute creerAutorisation(10000000000106);


/*------------appeler la function achat() en vendeuse----------------------*/
--procedure acheter() utilisee pour appeler la function achat() en vendeuse et recorde tout les commandes nous faisons.
--Editeur:Muhui YU
create or replace procedure acheter(
loginVendeur varchar2,
cle_autorisation varchar2,
refDevis integer)
is
  siretActeur number(14);
  siretBanque number(14);
  achat varchar2(255);
  resultat integer;
begin
  select siret into siretActeur from information where nom='entreprise';
  select siret into siretBanque from information where nom='banque';
  insert into commande values (seq_idc.nextval,loginVendeur,cle_autorisation,refDevis);
  achat := 'begin :1 :='||loginVendeur||'.achat(:2,:3,:4,:5); end;'; 
  execute immediate achat using out resultat, in siretActeur,in siretBanque,in cle_autorisation,in refDevis;
  if resultat=1 then
  dbms_output.put_line('Le achat a reussi! ');
  else dbms_output.put_line('Le achat a echoue! ');
  end if;
end;
/
show error;
--execute acheter('zzhai_a','B81D4AFB7A1F566EEBA62F4BBEAEDBED',24);
--execute acheter('ttroilo_a','ED29885C8B7B203029AE1AEBF1542CEC',20);
--execute acheter('yel_a','C4AE54E7B6D25F4CF1249ECFBD2887E5',108);



/*################################# PARTIE 4 Services proposes par la CCI ##################################################*/

/*&&&&&&&&&&&&&&&&&&&&&&&&&&& faire inscription on CCI &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
--function:Pour afficher le siret de l'entreprise
--Inscription(nomE VARCHAR2, login VARCHAR2, secteur VARCHAR2) return NUMBER
/*
declare
  siret number(14);
begin
  siret:= qrichar_a.inscription('SuperMachine','myu_a','commerce');
  dbms_output.put_line('Le siret de SuperMachine dans CCI est ' || siret);
  insert into information values (seq_idin.nextval,'entreprise','myu_a',siret,'');
end;
/
*/


/*&&&&&&&&&&&&&&&&& ajouter produit on CCI &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
--function: Pour referencer un nouveau produit dans CCI
--Cette procedure appelle le function de CCI ajout_produit
--ajout_produit(siretActeur  NUMBER(14), refArtVendeur INT, nomArticle VARCHAR2) return NUMBER
--Editeur:Shuying YE
create or replace procedure ajouterProduit(
refArt integer,
nomArticle varchar2)
is
  loginCCI varchar2(20);
  ajouter varchar2(255);
  resultat number(1);
  siretActeur number(14);
begin
  select siret into siretActeur from information where nom='entreprise';
  select loginOracle into loginCCI from information where nom='cci';
  ajouter := 'begin :1 :='||loginCCI||'.ajout_produit(:2,:3,:4); end;'; 
  execute immediate ajouter using out resultat,in siretActeur,in refArt,in nomArticle;
  dbms_output.put_line('Le resultat de ajout_produit est '||resultat);
end;
/
show error;
--execute ajouterProduit(6605,'IpadMini');


/*&&&&&&&&&&&&&&&&& suprimer  produit on CCI &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
--function:Pour dereferencer un produit dans CCI
--Cette procedure appelle le function de CCI suppr_produit
--suppr_produit(siretActeur  NUMBER(14), refArtVendeur  INT,  nomArticle VARCHAR2) return NUMBER
--Editeur:Shuying YE
create or replace procedure supprProduit(
refArt integer,
nomArticle varchar2)
is
  loginCCI varchar2(20);
  supprimer varchar2(255);
  resultat number(1);
  siretActeur number(14);
begin
  select siret into siretActeur from information where nom='entreprise';
  select loginOracle into loginCCI from information where nom='cci';
  supprimer := 'begin :1 :='||loginCCI||'.suppr_produit(:2,:3,:4); end;'; 
  execute immediate supprimer using out resultat,in siretActeur,in refArt,in nomArticle;
  dbms_output.put_line('Le resultat de ajout_produit est '||resultat);
end;
/
--execute supprProduit(6605,'IpadMini');


/*&&&&&&&&&&&&&&&&& loginParSiret(siretActeur  NUMBER)  on CCI &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
--function:Retourne ET affiche le login associe au SIRET specifie
--loginParSiret(siretActeur  NUMBER) return varchar2
/*
declare
  loginOracle varchar2(20);
begin
  loginOracle:= qrichar_a.loginParSiret(10000000000);
  dbms_output.put_line(loginOracle);
end;
/
*/

/*&&&&&&&&&&&&&&  Affiche le siret d'une entreprise grace a son nom  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
--execute qrichar_a.siretParNomEntreprise('SuperMachine');


/*&&&&&&&&&&&&&&  Afficher la liste de toutes les banques  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
--execute qrichar_a.consulterBanque;


/*&&&&&& Afficher la liste de toutes les Entreprises proposant le produit nomArticleRech &&&&&&&&&&&&&&&&&&&&&&&&&*/
--execute qrichar_a.rechercheProd(nomArticleRech VARCHAR2);



/*&&&&&&&&&&&&&&  faire une demande subvention a la CCI   &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
/*
Toutes les demandes sont etudiees. ATTENTION La CCI ne subventionne pas les banques 
retourne 1 et affiche un message si demande prise en compte, 0 et affiche un message sinon
*/
--Remarque: demandesubvention(siretActeur  NUMBER, montant REAL) return NUMBER 
/*
declare
  siretActeur number(14);
  subvention number(1);
begin
  select siret into siretActeur from information where nom='entreprise';
  subvention:= qrichar_a.demandesubvention(siretActeur,100);
  dbms_output.put_line(subvention);
end;
/
*/

/*&&&&&&&&&&&&&&  Consulter les function dans CCI   &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
--execute qrichar_a.listeFonctionsCCI;



/*################ PARTIE 5 Les autres Services proposes par la Banque #########################################################################*/

/*&&&&&&&&&&&&&&  ouvrir un compte dans la banque   &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
--Remarque: ouvertureCompte(numSiret, loginCCI) return int
/*
declare
  siretActeur number(14);
  loginCCI varchar2(20);
  compteBanque integer;
begin
  select siret into siretActeur from information where nom='entreprise';
  select loginOracle into loginCCI from information where nom='cci';
  compteBanque:=ngiovin_a.ouvertureCompte(siretActeur,loginCCI);
  dbms_output.put_line('La compte de banque est '||compteBanque);
  insert into information values (seq_idin.nextval,'banque','ngiovin_a','10000000000102',compteBanque);
end;
/
*/
--Banque 1:alaawad_a   siret:10000000000161 compte:1212
--Banque 1:ngiovin_a   siret:10000000000102 compte:68

/*&&&&&&&&&&&&&&&&&  consulter le compte de Banque  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
--Remarque: consultationCompte(numClient)
--execute ngiovin_a.consultationCompte(68);

/*&&&&&&&&&&&&&&&&&  Consulter les function dans Banque &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
--execute ngiovin_a.listeFonctionsBanque;

