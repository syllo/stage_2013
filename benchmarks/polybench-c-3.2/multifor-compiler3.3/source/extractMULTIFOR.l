/*****************************************************************************
*                                                                            *
*                       Multifor-compiler                                    * 
*                                                                            * 
*                                                                            *
*   Auteurs : Pr. Philippe CLAUSS & Imen FASSI                               *
*   Première version : Octobre 2012                                          *
*   Deuxième version : avril 2013                                            *
*   Troisième version : mai 2013                                             *
*   Description :                                                            * 
*   Ce code permet de vérifier la syntaxe d'un "multifor"                    *
*   et de le traduire en des "for" classiques                                *
*   en utilisant l'outil Polyédrique Cloog                                   *
*                                                                            *
*****************************************************************************/


%{
int Pile=0;
int Pile1=0; 
int AnPile=0;
int premMul=1;
FILE * temp;
FILE * outputt;
FILE * inputt;
FILE *fichier;
int multifor_parser (char * ) ;
int c;
int found=0;
int nbErr =0;
extern char * Message;
extern int oldmaxRef;
int maxRefAc=0;
int maxRefAc2=0;
%}
Var [a-zA-Z_]([a-zA-Z_]|[0-9])*
texte \"([^"])*\"
commentaire1  "/*""/"*([^*/]|"*"[^/]|[^*]"/")*"*"*"*/"
commentaire2 "//".*"\n"
%x MFOR
%%
"multifor" { BEGIN MFOR; found=1;
             temp = fopen("_multifor_Compiler_IBB_tempMul.c","w+");
             if (temp == NULL)
               printf("Impossible d'ouvrir le fichier _multifor_Compiler_IBB_tempMul.c");
             else
               fputs("multifor",temp);
           }
<MFOR>"{" { Pile++;
            if (temp != NULL)
              fputs("{",temp);
          }
<MFOR>"}" { Pile--;
            if (temp != NULL)
              fputs("}",temp);
            if(Pile==0) {
              if (temp != NULL)
                fclose(temp);
              nbErr=nbErr+multifor_parser("_multifor_Compiler_IBB_tempMul.c") ;
              // Copier le contenu de _multifor_Compiler_IBB_temp2.c dans _multifor_Compiler_IBB_OutPut.c + Ajout declarations des indices
              int i; // printf("*** Pile1:%d     AnPile:%d    premMul:%d\n",Pile1,AnPile,premMul);
              if ( premMul )  // declarations des indices de référence
              { premMul=0;
                 fprintf(outputt,"\n");
                 for (i=0;i<maxRefAc;i++) 
                    fprintf(outputt,"int _mfr_ref%d; ",i+oldmaxRef);
                 fprintf(outputt,"\n");
                 maxRefAc2=maxRefAc;
              }
              else
              { 
                 fprintf(outputt,"\n");
                 for (i=maxRefAc2;i<maxRefAc;i++) 
                    fprintf(outputt,"int _mfr_ref%d; ",i+oldmaxRef);
                 fprintf(outputt,"\n");
              }
              if (nbErr==0)
              {  fichier = fopen( "_multifor_Compiler_IBB_temp2.c", "r");
                 if (fichier == NULL)
                    printf("Impossible d'ouvrir le fichier _multifor_Compiler_IBB_temp2.c");
                 else
                 {  while ((c = getc(fichier)) != EOF) 
                       fprintf(outputt,"%c",c);
                    fclose(fichier);
                 } 
              }
              BEGIN(0);
              AnPile = Pile1;
            }
        }
<MFOR>.              { fputs(yyytext,temp); }
<MFOR>\n             { fputs(yyytext,temp); }
<MFOR>{texte}        { fputs(yyytext,temp); }
<MFOR>{commentaire1} { fputs(yyytext,temp); }
<MFOR>{commentaire2} { fputs(yyytext,temp); }
<MFOR>{Var}          { fputs(yyytext,temp); }


"{"            {fputs(yyytext,outputt); Pile1++; }
"}"            {fputs(yyytext,outputt); Pile1--; if(Pile1<AnPile) premMul=1;}  
.              {fputs(yyytext,outputt);}
\n             {fputs(yyytext,outputt);}
{texte}        {fputs(yyytext,outputt);}
{commentaire1} {fputs(yyytext,outputt);}
{commentaire2} {fputs(yyytext,outputt);}
{Var}          {fputs(yyytext,outputt);}

%%

int yyywrap ( ) {
   return 1;
}


int extraxt_and_parse (char * iinput) {
  Pile=0;
  found=0;
  yyyin = fopen(iinput,"r");
  outputt= fopen("_multifor_Compiler_IBB_OutPut.c","w+");
  if (outputt == NULL)
     printf("Impossible d'ouvrir le fichier OutPut.c");
  else
  {  yyylex();
     fclose(outputt);
  }
  if (nbErr)
  {  char * ch =NULL;
     ch= malloc(100);
     if (ch == NULL) 
     {  printf("L'allocation mémoire a échoué !\n");
        exit(0);
     }
     sprintf (ch,"\n\n\tÉCHEC !! Il existe %d erreur(s) !\n\n\n",nbErr); 
     Message= ch;
  }
 fclose(yyyin);
 return found ;
}
