# Documentação — `contabil.gmd_administrativo`

## Objetivo

A view `contabil.gmd_administrativo` consolida as despesas administrativas realizadas a partir da tabela `contabil.gmd`, separando os lançamentos conforme regras específicas de pacote, conta, filial, centro de custo e fornecedor.

A composição da base ocorre no CTE `queryset`, com blocos unidos por `UNION`.

---

## Fonte principal

```sql
contabil.gmd g
```

Tabela auxiliar de conta/pacote:

```sql
cadastro.conta_mega ct
```

Relacionamento:

```sql
g.conta = ct.conta
```

---

## Regra de Centro de Custo Administrativo

Alguns blocos usam:

```sql
g.cc in (
  select cc
  from cadastro.centro_de_custo
  where
      (cc in (111,121) or matriz = 'Administrativo')
      and cc not in (
        999000,999002,195,208,
        207,206,205,202,199
      )
)
```

---

# Blocos de composição

## Aluguel, Água/Energia, Internet/Telefone e Material de Informática

Pacotes: `50, 52, 59`

Conta: `789`

Filial: `196`

### Resumo

| Critério        | Valores    |
| --------------- | ---------- |
| Pacotes         | 50, 52, 59 |
| Conta adicional | 789        |
| Filial          | 196        |

---

## TI e Locação de Bens

Pacote: `66`

Conta: `932`

Contas excluídas: `789, 927`

Filiais: `196, 99`

### Resumo

| Critério         | Valores  |
| ---------------- | -------- |
| Pacote           | 66       |
| Conta adicional  | 932      |
| Contas excluídas | 789, 927 |
| Filiais          | 196, 99  |

---

## Engenharia

Pacote: `57`

Filiais: `196, 99`

Centro de custo: `Regra ADM`

### Resumo

| Critério        | Valores   |
| --------------- | --------- |
| Pacote          | 57        |
| Filiais         | 196, 99   |
| Centro de custo | Regra ADM |

---

## Financeiro Jurus

Pacote: `502`

### Resumo

| Critério | Valores |
| -------- | ------- |
| Pacote   | 502     |
| Filial   | Todas   |

---

## Marketing

Pacote: `60`

CC excluídos: `108,117,172`

### Resumo

| Critério     | Valores     |
| ------------ | ----------- |
| Pacote       | 60          |
| CC excluídos | 108,117,172 |

---

## RH, Suprimentos e Multas

Pacotes: `62,621,65,651`

Contas: `511,515`

Filial: `196`

Centro de custo: `Regra ADM`

### Resumo

| Critério        | Valores       |
| --------------- | ------------- |
| Pacotes         | 62,621,65,651 |
| Contas          | 511,515       |
| Filial          | 196           |
| Centro de custo | Regra ADM     |

---

## Regulatório e Benefícios

Pacotes: `61,622`

Filiais: `99,196`

Fornecedor excluído: `31248`

Centro de custo: `Regra ADM`

### Resumo

| Critério            | Valores   |
| ------------------- | --------- |
| Pacotes             | 61,622    |
| Filiais             | 99,196    |
| Fornecedor excluído | 31248     |
| Centro de custo     | Regra ADM |

---

## Transporte e Logística

Pacote: `67`

Contas excluídas: `932`

Filiais: `196,99`

Centro de custo: `Regra ADM`

### Resumo

| Critério         | Valores   |
| ---------------- | --------- |
| Pacote           | 67        |
| Contas excluídas | 932       |
| Filiais          | 196,99    |
| Centro de custo  | Regra ADM |

---

## Residual Administrativo

Pacotes excluídos:

```sql
50,52,57,58,59,60,61,62,65,
66,67,73,621,622,651,501,502
```

Contas excluídas:

```sql
511,515,498,789,932,933
```

Também exclui:

```sql
select pacote
from cadastro.pacote
where despesa = 0
```

### Resumo

| Critério          | Valores                                                 |
| ----------------- | ------------------------------------------------------- |
| Pacotes excluídos | 50,52,57,58,59,60,61,62,65,66,67,73,621,622,651,501,502 |
| Contas excluídas  | 511,515,498,789,932,933                                 |
| Centro de custo   | Regra ADM                                               |

---

# Filtros finais da view

Classificações consideradas:

- Despesas Lojas Consolidadas
- Investimentos Lojas Novas

Categoria excluída: `PIS/COFINS`

---

# Tratamento do documento

```sql
SUBSTRING_INDEX(
  SUBSTRING_INDEX(documento,'-',1),
',',-1)
```

---

# Agrupamento final

```sql
periodo,
filial,
conta,
cc,
classificacao,
categoria,
fornecedor,
documento
```

Valor final:

```sql
sum(valor) as despesa
```
