
CREATE OR REPLACE FUNCTION "SCH".trocar_duam_parcela_baixada(
	duam_para_baixar bigint,
	parcela_baixar bigint,
	duam_para_remover bigint,
	parcela_remover bigint,
	usuario integer)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
valor_duam numeric;
valor_duam_baixar numeric;
valor_diferenca numeric;
aviso bigint;
valor_duam_aviso numeric;
valor_duam_aviso_remover numeric;

BEGIN
	aviso = 269541;
	--verificar se duam para remover da baixa está baixado
	if (select "DATA_PGTO" from "SCH"."DUAM_IT" where "DUAM" = duam_para_remover and "PARCELA" = parcela_remover) != null then
		raise notice 'essa parcela do duam não está baixado';
		return;
	end if;
	
	
	--BUSCAR AVISO NA TABELA DE CRITICA
	SELECT "AVISO"

    FROM "SCH"."ITEM_CRITICA_BAIXA_DUAM"
    WHERE "DUAM" = duam_para_remover AND "PARCELA" = parcela_remover
    ORDER BY "AVISO" DESC LIMIT 1 INTO valor_duam_aviso_remover;

	--buscar o valor que foi pago
	select "VALOR_PAGO" from "SCH"."DUAM_IT" where "DUAM" = duam_para_remover and "PARCELA" = parcela_remover into valor_duam;
	
	--buscar O AVISO
	select "AVISO" from "SCH"."DUAM_IT" where "DUAM" = duam_para_remover and "PARCELA" = parcela_remover into valor_duam_aviso;
  	
	--buscar o valor devido para calcular a diferença
  	select "VALOR" from "SCH"."DUAM_IT" where "DUAM" = duam_para_baixar and "PARCELA" = parcela_baixar into valor_duam_baixar;
  	
	valor_diferenca = valor_duam_baixar - valor_duam;
	
 
	if (valor_duam_aviso = valor_duam_aviso_remover) then
		--remover o numero do aviso da tabela duam_it
		UPDATE "SCH"."DUAM_IT" DUAM
		SET "DATA_PGTO" = NULL,
		"AVISO" = 0,
		"VALOR_PAGO" = NULL

		WHERE DUAM."DUAM" = duam_para_remover AND DUAM."PARCELA" = parcela_remover;
		
		
		   --remover o duam da tabela tipo aviso
         DELETE FROM "SCH"."ITEM_AV"
    	    WHERE "DUAM" = duam_para_remover AND "PARCELA" = parcela_remover and "AVISO" = valor_duam_aviso_remover;
    
	    --remover o duam da tabela CRITICA
        DELETE FROM "SCH"."ITEM_CRITICA_BAIXA_DUAM"
    	    WHERE "DUAM" = duam_para_remover AND "PARCELA" = parcela_remover and "AVISO" = valor_duam_aviso_remover;
	
	    --REMOVER DA TABELA DE FECHAMENTO
    	DELETE FROM "SCH"."DUAM_AV_FECHAMENTO"
		    WHERE "DUAM" = duam_para_remover AND "PARCELA" = parcela_remover and "AVISO" = valor_duam_aviso_remover;
   
         --Cria auditoria
	    INSERT INTO "SCH"."ZAUDITOR"("ARQUIVO", "CHAVE", "DATA", "HORA", "USUARIO", "TP_MOV", "MODULO")
		    VALUES ('ITEM_AV', aviso::varchar || duam_para_remover::varchar || parcela_remover::varchar, now()::date, "SCH".get_hora_atual(true), usuario, 'exclusao', 'ARRECADAÇÃO');

	end if;
    
    --remover o duam da tabela CRITICA
        DELETE FROM "SCH"."ITEM_CRITICA_BAIXA_DUAM"
    	    WHERE "DUAM" = duam_para_remover AND "PARCELA" = parcela_remover and "AVISO" = valor_duam_aviso_remover;
    
    --para baixar o duam
    perform "SCH".fc_baixa_duam_parcela(duam_para_baixar,aviso,parcela_baixar, valor_duam, usuario );

    perform "SCH".fc_acerta_flag_duam(duam_para_remover);
	
	
	perform "SCH".fc_baixa_duams_gerar_Duam_diferenca(duam_para_baixar,parcela_baixar,valor_diferenca);
    
    raise notice 'BELEZA PURA, AGORA SÓ TESTAR  - % % % %',valor_duam_aviso, valor_duam_aviso_remover, valor_duam_aviso_remover, valor_duam_AVISO;

    
END;
$BODY$;


