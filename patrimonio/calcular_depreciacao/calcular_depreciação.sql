CREATE OR REPLACE FUNCTION "SCH".atualizar_valor_bem_patrimonio_depreciacao(
	)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
  patrimonTO         RECORD;
  valor_atualizado    numeric;	
  porcentagem		int default 100;
BEGIN
  --funcção feita a pedido da comissõ de patrimonio pelo Junior do CPD
  

    FOR patrimonTo in
	
	  SELECT "NR_TOMBAMENTO","DT_TOMBAMENTO","VL_DOCUMENTO","VL_BEM","ST_BEM","ID_CADSET", "CD_PRODUTO"
  	  FROM "SCH"."PATRIMON" WHERE "NR_TOMBAMENTO" IN (1,6,8,9,10,11,12,13,14,15,16,17,18,19,20)--"DT_TOMBAMENTO" <= '2006-12-31'
	  
  LOOP
  
  	IF (patrimonTo."ST_BEM" = 'I') THEN
		valor_atualizado := 0.1 * patrimonTo."VL_DOCUMENTO";
		RAISE NOTICE 'I';
	END IF;
	
	IF (patrimonTo."ST_BEM" = 'P') THEN
		valor_atualizado := 0.3 * patrimonTo."VL_DOCUMENTO";
		RAISE NOTICE 'P';
	END IF;
	
	IF (patrimonTo."ST_BEM" = 'R') THEN
		valor_atualizado := 0.5 * patrimonTo."VL_DOCUMENTO";
		RAISE NOTICE 'R';
	END IF;
	
	IF (patrimonTo."ST_BEM" = 'B') THEN
		valor_atualizado := 0.8 * patrimonTo."VL_DOCUMENTO";
		RAISE NOTICE 'B';
	END IF;
	
	IF (patrimonTo."ST_BEM" = 'O') THEN
		valor_atualizado := 1 * patrimonTo."VL_DOCUMENTO";
		RAISE NOTICE 'O';
	END IF;
	
	
	INSERT into "SCH"."HISTPAT" ("NR_TOMBAMENTO","DT_DOCUMENTO","CD_TRANSPAT",
		"VL_DOCUMENTO",	"ID_CADSET","HIST_TRANSACAO","ID_PATRIAND") 
		values (patrimonTo."NR_TOMBAMENTO",(SELECT NOW()),12,valor_atualizado,
			   patrimonTo."ID_CADSET",'REAVALIADO PELA COMISSÃO DE PATRIMONIO',patrimonTo."CD_PRODUTO");


    --inserir na tabela zauditor	
	INSERT INTO "SCH"."ZAUDITOR"
			(
				"ARQUIVO", "CHAVE", "DATA", "HORA",
				"USUARIO", "TP_MOV", "MODULO"
		   	)
			VALUES
			(
				'HISTPAT', patrimonTo."NR_TOMBAMENTO", now()::date, "SCH".get_hora_atual(true),
				384, 'inclusao', 'PATRIMÔNIO'
			);

	--atualizar tabela patrimonio
  	UPDATE "SCH"."PATRIMON" SET
    	"VL_BEM" = valor_atualizado,
    	"DT_TRANSACAO" = (select now()),
    	"CD_TRANSACAO" = 12,
		"VL_TRANSACAO" = patrimonTo."VL_BEM" - valor_atualizado,
		"HIST_TRANSACAO" = 'REAVALIADO PELA COMISSÃO DE PATRIMONIO'
	
  	WHERE "NR_TOMBAMENTO" = patrimonTo."NR_TOMBAMENTO";

  	RAISE NOTICE 'TOMBAMENTO %, PATRIMONIO %, VALOR %, SITUAÇÃO DO BEM %, VALOR ATUALIZADO %, valor bem %', patrimonTo."NR_TOMBAMENTO", patrimonTo."CD_PRODUTO",
	              patrimonTo."VL_BEM",patrimonTo."ST_BEM", valor_atualizado, patrimonTo."VL_BEM"; 
  END LOOP;
	
 
  --RAISE INFO 'valorBemAtualizado(%)', valorBemAtualizado;

END;
$BODY$;

