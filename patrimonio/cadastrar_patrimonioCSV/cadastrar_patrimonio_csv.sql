CREATE OR REPLACE FUNCTION "SCH".cadastrar_patrimonio_csv()

    RETURNS record
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	produto record;
	ds_produto character varying;
	tombamento integer;
BEGIN
  --funcção feita a pedido da comissõ de patrimonio pelo Junior do CPD
	tombamento = (select "VALOR"::bigint from "SCH"."ADMCAO" where "EXE" = 9999 and "TIPO" = 1425);
	tombamento := tombamento + 1;
	
	RAISE NOTICE 'NUMERO TOMBAMENTO INICIAL %', tombamento;

	for produto in 
		SELECT * from patrieduca
	loop 	
	
			SELECT "DS_PRODUTO" FROM "SCH"."PRODUTOS" 
			WHERE "CD_PRODUTO" = produto."produto" into ds_produto;
			
		  	--INSERIR O PATRIMONIO
			insert into "SCH"."PATRIMON"
			(
				"NR_TOMBAMENTO", "DT_TOMBAMENTO", "CD_PRODUTO", "CD_FORNEC",
				"ST_BEM", "DS_DETALHE", "USUARIO", "DESCRICAO_HISTORICO", "TP_AQUISICAO",
				"TIPO_SITUACAO"
			)
			VALUES
			(
				tombamento,(select now()), produto."produto", 1616520000196,
				produto."estado",ds_produto,2890 , 'INCORPORADO PELA COMISSÃO PERMANENTE DE PATRIMÔNIO ' || produto."referente",
				'IN', 1
			);
			--INSERIR AUDITORIA
			INSERT INTO "SCH"."ZAUDITOR"
			(
				"ARQUIVO", "CHAVE", "DATA", "HORA", 
				"USUARIO", "TP_MOV", "MODULO"
		   	)
			VALUES
			(
				'PATRIMON', tombamento, now()::date, "SCH".get_hora_atual(true),
				2890, 'inclusao', 'PATRIMÔNIO'
			);
	
			--INSERIR O ANDAMENTO DO PATRIMONIO
		  insert into "SCH"."PATRIAND"
		  (
			  "NR_TOMBAMENTO","DT_ANDAMENTO","RESPONSAVEL", "USUARIO", "DT_ALTERACAO", "ID_CADSET", "ST_BEM","TIPO_SITUACAO"
		  )
		  VALUES 
		  (
		  		tombamento,(select now()),produto."responsavel",2890,(select now()), produto."organograma",produto."estado",1
		  );
		  
		  INSERT INTO "SCH"."ZAUDITOR"
			(
				"ARQUIVO", "CHAVE", "DATA", "HORA", 
				"USUARIO", "TP_MOV", "MODULO"
		   	)
			VALUES
			(
				'PATRIAND', tombamento, now()::date, "SCH".get_hora_atual(true),
				2890, 'inclusao', 'PATRIMÔNIO'
			);
		  
		  --INSERIR O HISTORICO DO PATRIMONIO
		  INSERT into "SCH"."HISTPAT" 
		  (
		  	"NR_TOMBAMENTO","DT_DOCUMENTO","CD_TRANSPAT","VL_DOCUMENTO","ID_CADSET","HIST_TRANSACAO","ID_PATRIAND"
		  ) 
		  
		  values 
		  	(
		  		tombamento,(SELECT NOW()),13,produto."valor",
			   produto."organograma",'INSERIDO PELA COMISSÃO DE PATRIMONIO - ' || produto."referente",produto."produto"
			);		
	
		   INSERT INTO "SCH"."ZAUDITOR"
			(
				"ARQUIVO", "CHAVE", "DATA", "HORA", 
				"USUARIO", "TP_MOV", "MODULO"
		   	)
			VALUES
			(
				'HISTPAT', tombamento, now()::date, "SCH".get_hora_atual(true),
				2890, 'inclusao', 'PATRIMÔNIO'
			);
		
			--UPDATE DO PATRIMONIO
			UPDATE "SCH"."PATRIMON" SET
				"VL_BEM" = produto."valor",
				"DT_TRANSACAO" = (select now()),
				"CD_TRANSACAO" = 13,
				"VL_TRANSACAO" = produto."valor",
				"HIST_TRANSACAO" = 'INSERIDO PELA COMISSÃO DE PATRIMONIO ' || produto."referente",
				"VL_DOCUMENTO" = produto."valor",
				"ID_CADSET" = produto."organograma"

			WHERE "NR_TOMBAMENTO" = tombamento;
			
			INSERT INTO "SCH"."ZAUDITOR"
			(
				"ARQUIVO", "CHAVE", "DATA", "HORA",
				"CAMPO", "VL_NOVO","VL_ANTIGO",
				"USUARIO", "TP_MOV", "MODULO"
		   	)
			VALUES
			(
				'PATRIMON', tombamento, now()::date, "SCH".get_hora_atual(true),
				'VL_BEM',produto."valor",' ' ,
				2890, 'alteracao', 'PATRIMÔNIO'
			);
			
			UPDATE "SCH"."PARAM" SET
			"NR_TOMBAMENTO" = tombamento;
			
			update "SCH"."ADMCAO" SET
			"VALOR" = tombamento
			WHERE "EXE" = 9999 AND "TIPO" = 1425;
		  	  
			
		  raise notice 'tombamento %, produtos%, descricao %',tombamento, produto,ds_produto ;
		  
		  tombamento := tombamento + 1;
	end loop;
	return produto;
END;
$BODY$;

