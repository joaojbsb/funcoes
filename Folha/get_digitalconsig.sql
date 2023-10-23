
CREATE OR REPLACE FUNCTION public.get_digitalconsig(
	anos integer,
	meses integer)
    RETURNS SETOF record 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
	--função feita pelo Junior para verificar servidores que tiveram desconto no consignado
	--select * from get_digitalconsig(2023,9) 
	--as (matricula int, evento int, descricao character varying, valor bigint, nome CHARACTER VARYING,situacao_contrato TEXT, mes int, ano int)
	
	consignados record;
	contador integer default 0;
	CAPAFIN INTEGER;
	ITEMFIN INTEGER;
	
begin

	for consignados in
		SELECT 
			consig."matricula", 
			consig."evento",
			EVENTO."DS_CALCVER",
			consig."valor",
			contrato."NOME_PESSOA",
			
			case when (CONTRATO."DATA_DESLIG" ISNULL OR CONTRATO."DATA_DESLIG" > NOW()::DATE) THEN 'CONTRATO ATIVADO'
				ELSE 'CONTRATO INATIVO' END AS SITUACAO_CONTRATO,
			
			consig."mes",
			consig."ano"
		
		FROM "digitalconsig" consig
		inner join "SCH"."CONTRATO" contrato on contrato."MATRICULA" = consig."matricula"
		inner join "SCH"."CALCVER" EVENTO ON EVENTO."ID_CALCVER" = consig."evento"
		where "ano" = anos and "mes" = meses
	
	LOOP
		
		CAPAFIN := (SELECT "ID_CAPAFIN" FROM "SCH"."CAPAFIN"
					WHERE "TIPO_FOLHA" =1 AND "MATRICULA" = consignados."matricula" and "ANO" = anos and "MES" = meses);
					
		ITEMFIN	:= (SELECT "ID_ITEMFIN" FROM "SCH"."ITEMFIN"
				   WHERE "ID_CAPAFIN" = CAPAFIN AND "ID_CALCVER" = consignados."evento");		
					
		contador := contador +1;
		
		IF (ITEMFIN isnull) THEN
		
			RAISE NOTICE 'ESSE AQUI, matricula %, capafin %, nome %', consignados."matricula",CAPAFIN, consignados."NOME_PESSOA";
			
			RETURN NEXT consignados;
			
		END IF;
		
	END LOOP;	

END;
$BODY$;