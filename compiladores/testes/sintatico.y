%{
#include "lexico.c"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "utils.c"

int contaVar;
int rotulo = 0;
int tipo;

char escopo = 'g';
int deslocamento;



%}

%token T_PROGRAMA
%token T_INICIO
%token T_FIM
%token T_LEIA
%token T_ESCREVA
%token T_SE
%token T_ENTAO
%token T_SENAO
%token T_FIMSE
%token T_FACA
%token T_ENQTO
%token T_FIMENQTO
%token T_INTEIRO
%token T_LOGICO
%token T_MAIS
%token T_MENOS
%token T_VEZES
%token T_DIV
%token T_ATRIBUI
%token T_MAIOR
%token T_MENOR
%token T_IGUAL
%token T_E
%token T_OU
%token T_NAO
%token T_ABRE
%token T_FECHA
%token T_V 
%token T_F 
%token T_IDENTIF
%token T_NUMERO

%token T_RETORNE 
%token T_FUNC
%token T_FIMFUNC


%start programa 
%expect 1

%left T_E T_OU 
%left T_IGUAL 
%left T_MAIOR T_MENOR 
%left T_MAIS T_MENOS 
%left T_VEZES T_DIV 


%%


programa 
    : cabecalho 
        { contaVar = 0; 
        //escopo = 'g'
        }
    variaveis 
        { 
            mostraTabela();
            empilha(contaVar);
            //empilha(contaVar, 'n');
            if (contaVar) 
                fprintf(yyout,"\tAMEM\t%d\n", contaVar); 
            
        }
    // acrescentar as funcoes 
       funcoes //mudar para rotinas
        //acrescentar DSVS L0 e  L0 NADA aqui se tiver funcao o programa 

       T_INICIO lista_comandos T_FIM
        { 
            int conta = desempilha();
            //int conta = desempilha('n');
            if (conta)
                fprintf(yyout,"\tDMEM\t%d\n", conta); 
            fprintf(yyout,"\tFIMP\n");
        }
    ;

cabecalho
    : T_PROGRAMA T_IDENTIF
        { fprintf(yyout,"\tINPP\n"); }
    ;

variaveis
    :   /* vazio */
    | declaracao_variaveis
    ;

declaracao_variaveis
    : tipo lista_variaveis declaracao_variaveis
    | tipo lista_variaveis
    ;

tipo 
    : T_LOGICO
        { tipo = LOG; }
    | T_INTEIRO
        { tipo = INT; }
    ;

lista_variaveis
    : lista_variaveis T_IDENTIF 
        { 
          strcpy(elemTab.id, atoma);
          elemTab.end = contaVar;
          elemTab.tip = tipo;
          // elemTab.esc = escopo;
          insereSimbolo(elemTab);
          contaVar++; 
        }
    | T_IDENTIF
        { 
        strcpy(elemTab.id, atoma);
          elemTab.end = contaVar;
          elemTab.tip = tipo;
          insereSimbolo(elemTab);
          contaVar++;
        }
    ;

    /* rotinas 
    :  // n tem funcao
    |
        { printf("DSVS\tL0\n"); }
    funcoes 
        {printf("L0\tNADA\n"); } */


    /*  funcoes 
    : funcao
    | funcao funcoes 
    ;
    */
    

// regras para as funcoes
funcoes 
    : /* vazio */
    | funcao funcoes 
    ;

funcao 
    : T_FUNC tipo T_IDENTIF 
        {
            fprintf(yyout, "\tDSVS\tL%d\n", rotulo);
            strcpy(elemTab.id, atoma);
            elemTab.tip = tipo;
            elemTab.cat = 'f';
            elemTab.rot = ++rotulo;
            escopo = 'l';
            elemTab.esc = escopo;
            insereSimbolo(elemTab); 
            fprintf(yyout,"L%d\tENSP\n", rotulo);

        }
    /* inserir nome, tipo, cat, rotulo da funcao tabela de simbolos
    strcpy(elemTab.id, atomo);
    elemTab.tip = tipo;
    elemTab.cat = 'f';
    elemTab.rot = ++rotulo;
    elemTab.esc = escopo;
    ESCOPO = 'L';
    insereSimbolo(elemTab); 
    fprintf(yyout,"L%d\tENSP\n", rotulo)*/
    T_ABRE parametros T_FECHA 
    // ajustar_parametros(); -> funcao que vai decidir o endereço dos param e func, e também vai gerar o vetor de parametros e o npar
    variaveis T_INICIO lista_comandos T_FIMFUNC //lancar rotulo na tabela
    // remover_variaveis_locais();
    {
        escopo = 'g';
    }
    ;

parametros 
    : /* vazio */ //adicionar na tabela de simbolos
    | parametro parametros  //alteracao feita pelo professor
    ;

parametro 
    : tipo T_IDENTIF        //alteracao feita pelo professor
    //cadastrar o parametro, ir ajustando até chegar no nome da funcao, ultimo param = -3
    ;
    
lista_comandos
    :
    | comando lista_comandos
    ;

comando 
    : entrada_saida
    | repeticao 
    | selecao
    | atribuicao 
    | retorno // alteracao feita pelo professor
    ;

retorno 
    : T_RETORNE expressao  
        // verificar se esta num escopo local
        // verificar se o tipo da expressao eh compativel
        // deve gerar (depois da trad. da expressao)
        // ARZL (valor de retorno), DMEM (se tiver variavel local)
        // RTSP n
        // se tiver global, ele da erro, so retorna local
    ;

entrada_saida
    : leitura
    | escrita
    ;


leitura 
    : T_LEIA T_IDENTIF
        
        { 
            int pos = buscaSimbolo(atoma);
            fprintf(yyout,"\tLEIA\n\tARZG\t%d\n", tabSimb[pos].end); 
        }
    ;

escrita 
    : T_ESCREVA expressao 
        {
            desempilha(); 
            //desempilha('t');
            fprintf(yyout,"\tESCR\n"); 
        }
    ;

repeticao 
    : T_ENQTO
        { 
            fprintf(yyout,"L%d\tNADA\n", ++rotulo); 
            empilha(rotulo);
            //empilha(rotulo, 'r');
        } 
    expressao T_FACA  
        {   
            int tip = desempilha();
            if (tip != LOG)
                yyerror("Incompatibilidade de tipo");
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo); 
            empilha(rotulo);
            //empilha(rotulo, 'r');
        }
    lista_comandos
    T_FIMENQTO
        {
            mostraPilha();
            int rot1 = desempilha();
            //int rot1 = desempilha('r');
            int rot2 = desempilha();
            //int rot2 = desempilha('r');
            fprintf(yyout,"\tDSVS\tL%d\nL%d\tNADA\n", rot2, rot1); 

        }
    ;

selecao 
    : T_SE expressao T_ENTAO 
        { 
            int tip = desempilha();
            if (tip != LOG)
                yyerror("Incompatibilidade de tipo");
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo);
            empilha(rotulo); 
            //empilha(rotulo, 'r'); 
        }
    lista_comandos T_SENAO 
        {
            int rot = desempilha(); 
            fprintf(yyout,"\tDSVS\tL%d\nL%d\tNADA\n", ++rotulo, rot); 
            empilha(rotulo);
            //empilha(rotulo, 'r'); 
        }
    lista_comandos T_FIMSE
        {
            int rot = desempilha(); 
            //int rot = desempilha('r'); 
            fprintf(yyout,"L%d\tNADA\n", rot); 
        }
    ;

atribuicao 
    : T_IDENTIF
        {
            int pos = buscaSimbolo(atoma);
            empilha(pos);
            //empilha(pos, 'p');
        } 
      T_ATRIBUI expressao 
        { 
            //mostraPilha();
            int tip = desempilha();
            //int tip = desempilha('t');
            int pos = desempilha();
            //int pos = desempilha('p');
            if (tabSimb[pos].tip != tip)
                yyerror("Incompatibilidade de tipo!");
            fprintf(yyout,"\tARZG\t%d\n", tabSimb[pos].end); 
        }

expressao 
    : expressao T_VEZES expressao 
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tMULT\n"); 
        
        }
    | expressao T_DIV expressao 
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tDIVI\n"); 
        }
    | expressao T_MAIS expressao
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tSOMA\n"); 
        } 
    | expressao T_MENOS expressao
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tSUBT\n"); 
        } 
    | expressao T_MAIOR expressao
        { 
            testaTipo(INT, INT, LOG);
            fprintf(yyout,"\tCMMA\n"); 
        } 
    | expressao T_MENOR expressao 
        { 
            testaTipo(INT, INT, LOG);
            fprintf(yyout,"\tCMME\n"); 
        }
    | expressao T_IGUAL expressao
        { 
            testaTipo(INT, INT, LOG);
            fprintf(yyout,"\tCMIG\n"); 
        } 
    | expressao T_E expressao 
        { 
            testaTipo(LOG, LOG, LOG);
            fprintf(yyout,"\tCONJ\n"); 
        }
    | expressao T_OU expressao
        { 
            testaTipo(LOG, LOG, LOG);
            fprintf(yyout,"\tDISJ\n"); 
        } 
    | termo 
    ;

identificador 
    : T_IDENTIF 
    // { int pos = buscaSimbolo(atoma);
        //empilha (pos, 'p')
        //}
    // código aqui
    ;

// A funcao eh chamada como um termo numa expressao
chamada 
    : // sem parenteses eh uma variavel
    /*  int pos = desempilha('p');
        if (tabSim[pos].esc == 'g')
            fprintf(yyout,"\tCRVG\t%d\n", tabSimb[pos].end);
        else
            fprintf(yyout,"\tCRVl\t%d\n", tabSimb[pos].end);
        empilha(tabSimb[pos].tip, 't');                         <<<<<- COLOCAR AQUI SÓ PRA TESTE DA PILHA SEMANTICA
    */
    | T_ABRE 
    // código aqui "AMEM 1"
    //fprintf(yyout,"\tAMEM 1\n");
    lista_argumentos T_FECHA 
    /*{
        int pos = desempilha('p');
        fprintf(yyout, "\tSVCP\n");
        fprintf(yyout, "\tDSVS\t%d\n", tabSimb[pos].rot);
    }*/
    //talvez seja argumentos
    // ter uma funcao para contar o numero de argumentos
    // SVCP E DSVS AQUI 
    ;

lista_argumentos 
    :   /* vazio */
    | expressao lista_argumentos
    ;

termo 
    : identificador chamada
    // tudo isso abaixo, vai ter que ser colocado em outro lugar
    /* : T_IDENTIF
        { 
            int pos = buscaSimbolo(atoma);
            fprintf(yyout,"\tCRVG\t%d\n", tabSimb[pos].end);
            empilha(tabSimb[pos].tip);
            empilha(tabSimb[pos].tip, 't');
        } */
    | T_NUMERO
        {   fprintf(yyout,"\tCRCT\t%s\n", atoma); 
            empilha(INT);
            //empilha(INT, 't');
        }
    | T_V 
        {   fprintf(yyout,"\tCRCT\t1\n"); 
            empilha(LOG);
            //empilha(LOG, 't');
        }
    | T_F 
        {   fprintf(yyout,"\tCRCT\t0\n"); 
            empilha(LOG);
            //empilha(LOG, 't');
        }
    | T_NAO termo
        { 
            int t = desempilha();
            if (t != LOG) yyerror ("Incompatibilidade de tipo!");
            fprintf(yyout,"\tNEGA\n"); 
            empilha(LOG);
            //empilha(LOG, 't');
        }
    | T_ABRE expressao T_FECHA
    ;

%%


int main (int argc, char *argv[]) {
    char *p, nameIn[100], nameOut[100];
    argv++;
    if (argc < 2) {
        puts("\nCompilador Simples");
        puts("\n\tUso: ./simples <NOME>[.simples]\n\n");
        exit(10);
    }
    p = strstr(argv[0], ".simples");
    if (p) *p = 0;
    strcpy(nameIn, argv[0]);
    strcat(nameIn, ".simples");
    strcpy(nameOut, argv[0]);
    strcat(nameOut, ".mvs");
    yyin = fopen (nameIn, "rt");
    if (!yyin) {
        puts("Programa fonte não encontrado!");
        exit(20);
    }
    yyout = fopen(nameOut, "wt");
    yyparse();
    puts("Programa ok!");
}