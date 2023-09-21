CREATE OR REPLACE FUNCTION "SCH".fc_repactuacao_super_refis_pessoa(
	tipo_devedor character varying,
	devedor bigint,
	data_inicial date,
	data_final date,
	receita_repac integer,
	codbaixa integer,
	vencimento date,
	tipo_debito character varying,
	tipo_simulacao character varying,
	valor_parcelas numeric,
	codigo_refis bigint,
	usuario integer,
	receitas character varying,
	duams character varying,
	obs character varying,
	tipo_entrada character varying,
	percentual_valor_entrada numeric,
	outras_receitas character varying,
	tipopesquisa integer)
    RETURNS bigint
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE 
	tem_debito boolean;
	
BEGIN
--feito por Junior CPD

	tem_debito = (select * from "SCH".fnc_debitos_vencidos_pessoa_palmas(devedor));
	RAISE NOTICE 'TEM DEBITOS % CCP % ', tem_debito, devedor;
	if (tem_debito = 't') then	
	
		return "SCH".fc_repactuacao(tipo_devedor,devedor,data_inicial,data_final,receita_repac,
				codbaixa,vencimento,tipo_debito,tipo_simulacao,valor_parcelas,codigo_refis,usuario,receitas,duams,obs,
				tipo_entrada,percentual_valor_entrada, outras_receitas, 0, tipoPesquisa);
	else
		
		return devedor;
	end if;
END;
$BODY$;