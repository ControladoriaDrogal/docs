-- #### Realizado ####
create or replace view contabil.gmd_administrativo as
with queryset as (
-- PCT: Aluguel (50), Consumo Água e Energia (52), Internet e Telefone (59) ou conta Material de Informática (ct 789) => Baseado na Filial, desconsiderando a Entidade
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor, g.documento
from contabil.gmd g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	(ct.pacote in (50, 52, 59) or ct.conta = 789)
	and g.filial = 196
-- 
union
-- PCT: TI (66) exceto Material de Informática (789) ou locação de bens (ct 932) => filiais 99 e 196 (Desconsiderar Manutenção de uso de software Manipulação (927))
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor, g.documento
from contabil.gmd g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	(ct.pacote = 66 or ct.conta = 932)
	and ct.conta not in (789, 927)
	and g.filial in (196, 99)
-- 
union
-- PCT: Engenharia (57) => filiais 99 e 196 e Entidade ADM
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor, g.documento
from contabil.gmd g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote = 57
	and g.filial in (196, 99)
	and g.cc in (select cc from cadastro.centro_de_custo where (cc in (111, 121) or matriz = 'Administrativo' ) and cc not in (999000, 999002, 195, 208, 207, 206, 205, 202, 199))
-- 
union
-- PCT: Financeiro Jurus (502) => Considerar 100%
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor, g.documento
from contabil.gmd g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote = 502
-- 
union
-- PCT: MKT (60) => Considerar 100% o pacote exceto CC do digital (108, 117, 172)
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor, g.documento
from contabil.gmd g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote = 60
	and g.cc not in (108, 117, 172)
-- 
union
-- PCT: RH (62, 621), Suprimentos (65, 651) / Conta Multas (511, 515) => Baseado na Entidade ADM + CC Supervisão e Momento Saúde + 196
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor, g.documento
from contabil.gmd g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	(ct.pacote in (62, 621, 65, 651) or ct.conta in (511, 515))
	and g.filial = 196
	and g.cc in (select cc from cadastro.centro_de_custo where (cc in (111, 121) or matriz = 'Administrativo' ) and cc not in (999000, 999002, 195, 208, 207, 206, 205, 202, 199))
--
union	
-- Regulatório (61) e Beneficio (622) => Matriz Adm  + CC Supervisão e Momento Saúde e filial 99 e 196
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor, g.documento
from contabil.gmd g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote in (61, 622)
	and g.filial in (99, 196)
	and g.cc in (select cc from cadastro.centro_de_custo where (cc in (111, 121) or matriz = 'Administrativo' ) and cc not in (999000, 999002, 195, 208, 207, 206, 205, 202, 199))
	and g.cod_fornecedor <> 31248
--
union	
-- PCT: Transporte Logistica (67) exceto locação de bens (ct 932) e Pedágio (ct 933) => Considerar 100% o pacote exceto CC do digital (108, 117, 172)
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor, g.documento
from contabil.gmd g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote = 67
	and g.conta not in (932)
	and g.cc in (select cc from cadastro.centro_de_custo where (cc in (111, 121) or matriz = 'Administrativo' ) and cc not in (999000, 999002, 195, 208, 207, 206, 205, 202, 199))
-- 
union
-- Baseado na Entidade ADM + CC Supervisão e Momento Saúde  + CC Supervisão e Momento Saúde
-- Todoas Exceto Pacotes considerado acima e a conta Conta Multas (511, 515)
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor, g.documento
from contabil.gmd g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote not in (50, 52, 57, 58, 59, 60, 61, 62, 65, 66, 67, 73, 621, 622, 651, 501, 502)
	and ct.pacote not in (select pacote from cadastro.pacote where despesa = 0)
	and ct.conta not in (511, 515, 498, 789, 932, 933, 9005)
	and g.cc in (select cc from cadastro.centro_de_custo where (cc in (111, 121) or matriz = 'Administrativo' ) and cc not in (999000, 999002, 195, 208, 207, 206, 205, 202, 199))
)
select
	periodo,
	filial,
	conta,
	cc,
	classificacao,
	categoria,
	fornecedor,
	SUBSTRING_INDEX(SUBSTRING_INDEX(documento, '-', 1), ',', -1) as documento,
	sum(valor) as despesa
from queryset
where classificacao in ('Despesas Lojas Consolidadas', 'Investimentos Lojas Novas') and upper(categoria) <> 'PIS/COFINS'
group by 1, 2, 3, 4, 5, 6, 7, 8;


-- #### Orçado ####
create or replace view contabil.gmd_administrativo_orcado as
with queryset as (
-- PCT: Aluguel (50), Consumo Água e Energia (52), Internet e Telefone (59) ou conta Material de Informática (ct 789) => Baseado na Filial, desconsiderando a Entidade
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor
from contabil.gmd_orcamento g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	(ct.pacote in (50, 52, 59) or ct.conta = 789)
	and g.filial = 196
-- 
union
-- PCT: TI (66) exceto Material de Informática (789) ou locação de bens (ct 932) => filiais 99 e 196 (Desconsiderar Manutenção de uso de software Manipulação (927))
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor
from contabil.gmd_orcamento g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	(ct.pacote = 66 or ct.conta = 932)
	and ct.conta not in (789, 927)
	and g.filial in (196, 99)
-- 
union
-- PCT: Engenharia (57) => filiais 99 e 196 e Entidade ADM
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor
from contabil.gmd_orcamento g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote = 57
	and g.filial in (196, 99)
	and g.cc in (select cc from cadastro.centro_de_custo where (cc in (111, 121) or matriz = 'Administrativo' ) and cc not in (999000, 999002, 195, 208, 207, 206, 205, 202, 199))
-- 
union
-- PCT: Financeiro Jurus (502) => Considerar 100%
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor
from contabil.gmd_orcamento g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote = 502
-- 
union
-- PCT: MKT (60) => Considerar 100% o pacote exceto CC do digital (108, 117, 172)
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor
from contabil.gmd_orcamento g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote = 60
	and g.cc not in (108, 117, 172)
-- 
union
-- PCT: RH (62, 621), Suprimentos (65, 651) / Conta Multas (511, 515) => Baseado na Entidade ADM + CC Supervisão e Momento Saúde + 196
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor
from contabil.gmd_orcamento g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	(ct.pacote in (62, 621, 65, 651) or ct.conta in (511, 515))
	and g.filial = 196
	and g.cc in (select cc from cadastro.centro_de_custo where (cc in (111, 121) or matriz = 'Administrativo' ) and cc not in (999000, 999002, 195, 208, 207, 206, 205, 202, 199))
--
union	
-- Regulatório (61) e Beneficio (622) => Matriz Adm  + CC Supervisão e Momento Saúde e filial 99 e 196
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor
from contabil.gmd_orcamento g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote in (61, 622)
	and g.filial in (99, 196)
	and g.cc in (select cc from cadastro.centro_de_custo where (cc in (111, 121) or matriz = 'Administrativo' ) and cc not in (999000, 999002, 195, 208, 207, 206, 205, 202, 199))
--
union	
-- PCT: Transporte Logistica (67) exceto locação de bens (ct 932) e Pedágio (ct 933) => Considerar 100% o pacote exceto CC do digital (108, 117, 172)
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor
from contabil.gmd_orcamento g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote = 67
	and g.conta not in (932)
	and g.cc in (select cc from cadastro.centro_de_custo where (cc in (111, 121) or matriz = 'Administrativo' ) and cc not in (999000, 999002, 195, 208, 207, 206, 205, 202, 199))
-- 
union
-- Baseado na Entidade ADM + CC Supervisão e Momento Saúde  + CC Supervisão e Momento Saúde
-- Todoas Exceto Pacotes considerado acima e a conta Conta Multas (511, 515)
select g.periodo, g.filial, g.conta, g.cc, g.valor, g.classificacao, g.categoria, g.fornecedor
from contabil.gmd_orcamento g
left join cadastro.conta_mega ct on g.conta = ct.conta
where 
	ct.pacote not in (50, 52, 57, 58, 59, 60, 61, 62, 65, 66, 67, 73, 621, 622, 651, 501, 502)
	and ct.pacote not in (select pacote from cadastro.pacote where despesa = 0)
	and ct.conta not in (511, 515, 498, 789, 932, 933, 9005)
	and g.cc in (select cc from cadastro.centro_de_custo where (cc in (111, 121) or matriz = 'Administrativo' ) and cc not in (999000, 999002, 195, 208, 207, 206, 205, 202, 199))
)
select
	periodo,
	filial,
	conta,
	cc,
	classificacao,
	categoria,
	fornecedor,
	sum(valor) as despesa
from queryset
where classificacao in ('Despesas Lojas Consolidadas', 'Investimentos Lojas Novas') and upper(categoria) <> 'PIS/COFINS'
group by 1, 2, 3, 4, 5, 6, 7;
