-- FUNCTION: SCH.cadastrar_patrimonio(integer, integer, character varying, integer, integer)

-- DROP FUNCTION IF EXISTS "SCH".cadastrar_patrimonio(integer, integer, character varying, integer, integer);

CREATE OR REPLACE FUNCTION "SCH".cadastrar_patrimonio(
	cd_produto integer,
	mat_responsavel integer,
	organograma character varying,
	quantidade integer,
	usuario integer)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	qtd_tombamento int;
	produto record;
	tombamento integer;
BEGIN
  --função feita para cadastrar patrimonio em massa, a pedido da comissõ de patrimonio pelo Junior do CPD
  
	tombamento = (select "VALOR"::bigint from "SCH"."ADMCAO" where "EXE" = 9999 and "TIPO" = 1425);
	qtd_tombamento := tombamento + quantidade;
	tombamento := tombamento + 1;
	
	RAISE NOTICE 'NUMERO TOMBAMENTO %', tombamento;

	while tombamento <= qtd_tombamento
	loop 	
			SELECT "DS_PRODUTO" FROM "SCH"."PRODUTOS" 
			WHERE "CD_PRODUTO" = cd_produto into produto;
			
		  	--INSERIR O PATRIMONIO
			insert into "SCH"."PATRIMON"
			(
				"NR_TOMBAMENTO", "DT_TOMBAMENTO", "CD_PRODUTO", "CD_FORNEC",
				"ST_BEM", "DS_DETALHE", "USUARIO", "DESCRICAO_HISTORICO", "TP_AQUISICAO",
				"TIPO_SITUACAO"
			)
			VALUES
			(
				tombamento,(select now()), cd_produto, 1616520000196,
				'R',produto."DS_PRODUTO", usuario, 'INCORPORADO PELA COMISSÃO PERMANENTE DE PATRIMÔNIO',
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
				usuario, 'inclusao', 'PATRIMÔNIO'
			);
	
			--INSERIR O ANDAMENTO DO PATRIMONIO
		  insert into "SCH"."PATRIAND"
		  (
			  "NR_TOMBAMENTO","DT_ANDAMENTO","RESPONSAVEL", "USUARIO", "DT_ALTERACAO", "ID_CADSET", "ST_BEM","TIPO_SITUACAO"
		  )
		  VALUES 
		  (
		  		tombamento,(select now()),mat_responsavel,usuario,(select now()), organograma,'R',1
		  );
		  
		  INSERT INTO "SCH"."ZAUDITOR"
			(
				"ARQUIVO", "CHAVE", "DATA", "HORA", 
				"USUARIO", "TP_MOV", "MODULO"
		   	)
			VALUES
			(
				'PATRIAND', tombamento, now()::date, "SCH".get_hora_atual(true),
				usuario, 'inclusao', 'PATRIMÔNIO'
			);
		  
		  --INSERIR O HISTORICO DO PATRIMONIO
		  INSERT into "SCH"."HISTPAT" 
		  (
		  	"NR_TOMBAMENTO","DT_DOCUMENTO","CD_TRANSPAT","VL_DOCUMENTO","ID_CADSET","HIST_TRANSACAO","ID_PATRIAND"
		  ) 
		  
		  values 
		  	(
		  		tombamento,(SELECT NOW()),13,50,
			   organograma,'INSERIDO PELA COMISSÃO DE PATRIMONIO',cd_produto
			);		
	
		   INSERT INTO "SCH"."ZAUDITOR"
			(
				"ARQUIVO", "CHAVE", "DATA", "HORA", 
				"USUARIO", "TP_MOV", "MODULO"
		   	)
			VALUES
			(
				'HISTPAT', tombamento, now()::date, "SCH".get_hora_atual(true),
				usuario, 'inclusao', 'PATRIMÔNIO'
			);
		
			--UPDATE DO PATRIMONIO
			UPDATE "SCH"."PATRIMON" SET
				"VL_BEM" = 50,
				"DT_TRANSACAO" = (select now()),
				"CD_TRANSACAO" = 13,
				"VL_TRANSACAO" = 50,
				"HIST_TRANSACAO" = 'INSERIDO PELA COMISSÃO DE PATRIMONIO',
				"VL_DOCUMENTO" = 50,
				"ID_CADSET" = organograma

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
				'VL_BEM'::CHAR,'50','' ,
				usuario, 'alteracao', 'PATRIMÔNIO'
			);
			
			UPDATE "SCH"."PARAM" SET
			"NR_TOMBAMENTO" = tombamento;
			
			update "SCH"."ADMCAO" SET
			"VALOR" = tombamento
			WHERE "EXE" = 9999 AND "TIPO" = 1425;
		  	  

		  raise notice 'Tombamento + 1 % até o tombamento %, e tombamento é %',tombamento, qtd_tombamento, tombamento;
		  
		  tombamento := tombamento + 1;
		  
	end loop;
END;
$BODY$;

ALTER FUNCTION "SCH".cadastrar_patrimonio(integer, integer, character varying, integer, integer)
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION "SCH".cadastrar_patrimonio(integer, integer, character varying, integer, integer) TO PUBLIC;

GRANT EXECUTE ON FUNCTION "SCH".cadastrar_patrimonio(integer, integer, character varying, integer, integer) TO "SELECT_GROUP";

GRANT EXECUTE ON FUNCTION "SCH".cadastrar_patrimonio(integer, integer, character varying, integer, integer) TO postgres;

