# AirportPro 

> Análise Profissional de Aeroportos e Pistas conforme RBAC-154 e ICA 11-408

<!-- badges: start -->
[![R-CMD-check](https://github.com/username/AirportPro/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/username/AirportPro/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

## Visão Geral

**AirportPro** é um pacote R especializado em análise técnica de aeroportos brasileiros, desenvolvido para facilitar o trabalho de engenheiros, consultores e profissionais da aviação civil. O pacote implementa as normas RBAC-154 (ANAC) e ICA 11-408 (DECEA) para cálculo automático de:

- **Faixas de Pista** (Runway Strips) conforme RBAC-154
- **Superfícies Limitadoras de Obstáculos (OLS)** conforme ICA 11-408
- **Visualização Geoespacial** interativa com Leaflet
- **Conversão para formatos espaciais** (sf/GeoJSON)
- **Relatórios técnicos** automatizados

## Características Principais

- ✈️ Cálculo automatizado de dimensões de faixas de pista (RBAC-154)
- 📐 Superfícies limitadoras ICA 11-408 (Aproximação, Transição, Horizontal, etc.)
- 🗺️ Mapas interativos com Leaflet (múltiplas camadas, popup detalhado)
- 📊 Suporte a operações de precisão e não-precisão (ILS-CAT-I/II/III, VOR, NDB)
- 🌐 Entrada/saída em formato JSON padronizado
- 📦 Integração completa com ecossistema `sf` (Simple Features)
- 🎯 Validação automática de parâmetros normativos
- 📋 Classe R6 orientada a objetos

## Instalação

### Instalação via GitHub (Desenvolvimento)

```r
# install.packages("devtools")
devtools::install_github("username/AirportPro")
```

### Instalação do CRAN (quando disponível)

```r
install.packages("AirportPro")
```

## Início Rápido

### 1. Carregar Aeroporto de Arquivo JSON

```r
library(AirportPro)

# Carregar aeroporto do arquivo JSON estruturado
aeroporto <- Airport$new("caminho/para/aeroporto.json")

# Visualizar informações básicas
print(aeroporto)
#> ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#> 🛫 SBPA — Aeroporto Internacional de Porto Alegre - Salgado Filho
#> ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#> 📍 Município/UF: Porto Alegre / RS
#> 🌐 ARP: -29.996°, -51.171° | Elevação: 3.40 m
#> 📐 Datum: SIRGAS2000 | CRS: EPSG:32722
#>
#> Pistas:
#>   • 11/29 — 3200 m × 45 m (ASFALTO) [4D]
#>     ↘ THR 11: ILS-CAT-II @ 109.5°
#>     ↘ THR 29: VOR/DME @ 289.5°
```

### 2. Consultar Superfícies Limitadoras

```r
# Listar todas as superfícies disponíveis
aeroporto$list_superficies()
#> Cabeceiras disponíveis com superfícies ICA 11-408:
#>   • 11_11 (Pista 11/29, THR 11) — ILS-CAT-II
#>   • 11_29 (Pista 11/29, THR 29) — VOR/DME

# Obter parâmetros completos de uma cabeceira
sup <- aeroporto$get_superficie(id = "11_11")
names(sup)
#> [1] "approach"     "inner_horiz"  "conical"      "outer_horiz"
#> [5] "transition"   "balked_ldg"   "takeoff"
```

### 3. Visualização Interativa

```r
# Converter pistas para objetos espaciais (sf)
pistas_sf <- lapply(aeroporto$pistas, runway_to_sf)

# Criar mapa interativo com Leaflet
mapa <- plot_all_runways_leaflet(pistas_sf)
mapa  # Visualizar no RStudio Viewer ou navegador
```

### 4. Adicionar Camadas ao Mapa

```r
library(leaflet)

# Obter superfície de aproximação
sup_approach <- get_superficie(aeroporto, id = "11_11")

# Adicionar ao mapa
mapa <- mapa %>%
  add_to_map(sup_approach$approach,
             color = "#FF6B35",
             label = "Aproximação THR 11")
```

## Estrutura de Dados JSON

O pacote utiliza um formato JSON estruturado para entrada de dados. Exemplo:

```json
{
  "versao_estrutura": "1.0.3",
  "aeroporto": {
    "icao": "SBPA",
    "nome": "Aeroporto Internacional de Porto Alegre",
    "municipio": "Porto Alegre",
    "estado": "RS",
    "geodesia": {
      "latitude_arp": -29.995833,
      "longitude_arp": -51.171111,
      "elevacao_arp_m": 3.4,
      "crs_planar": "EPSG:32722",
      "geoid": "SIRGAS2000"
    },
    "pistas": [
      {
        "identificacao": "11/29",
        "comprimento_m": 3200,
        "largura_m": 45,
        "tipo_pavimento": "ASFALTO",
        "approach_type": "precision",
        "codigo_referencia": {
          "numero": 4,
          "letra": "D"
        },
        "cabeceiras": [
          {
            "designador": "11",
            "latitude_thr": -29.99444,
            "longitude_thr": -51.18306,
            "elevacao_thr_m": 3.4,
            "rumo_verdadeiro_graus": 109.5,
            "tecnologia_aproximacao": "ILS-CAT-II"
          }
        ]
      }
    ]
  }
}
```

Veja os exemplos completos em `inst/extdata/`:
- `ad_sbpa.json` — Porto Alegre/RS (Salgado Filho)
- `ad_sbfl.json` — Florianópolis/SC (Hercílio Luz)
- `ad_sncw.json` — Caçador/SC

## Normas Implementadas

### RBAC-154 (ANAC, 2019)

Parâmetros de faixa de pista conforme:
- Código de referência do aeródromo (1A até 4F)
- Tipo de operação (precisão/não-precisão)
- Largura e comprimento da faixa
- Zonas de proteção de fim de pista (RESA)

### ICA 11-408 (DECEA, Tabela 4-3)

Superfícies limitadoras de obstáculos:
- **Aproximação** (Approach Surface)
- **Transição** (Transitional Surface)
- **Horizontal Interna** (Inner Horizontal Surface)
- **Cônica** (Conical Surface)
- **Horizontal Externa** (Outer Horizontal Surface)
- **Decolagem** (Takeoff Climb Surface)
- **Pouso Interrompido** (Balked Landing Surface)

## Funções Principais

| Função | Descrição |
|--------|-----------|
| `Airport$new()` | Cria objeto aeroporto de arquivo JSON |
| `list_superficies()` | Lista cabeceiras e suas superfícies |
| `get_superficie()` | Obtém parâmetros completos de uma superfície |
| `runway_to_sf()` | Converte pista para objeto `sf` |
| `runway_strip_to_sf()` | Converte faixa de pista para objeto `sf` |
| `plot_all_runways_leaflet()` | Cria mapa interativo com Leaflet |
| `plot_airport_layers()` | Plota múltiplas camadas em um mapa |
| `add_to_map()` | Adiciona camada espacial a mapa existente |

## Dependências

### Pacotes Obrigatórios
- `R6` — Programação orientada a objetos
- `dplyr` — Manipulação de dados
- `sf` — Análise espacial (Simple Features)
- `geosphere` — Cálculos geodésicos
- `leaflet` — Mapas interativos
- `jsonlite` — Leitura/escrita JSON

### Pacotes Sugeridos
- `testthat` — Testes automatizados
- `knitr` / `rmarkdown` — Documentação
- `plotly` — Visualizações avançadas
- `pkgdown` — Site de documentação

## Exemplos de Uso

### Exemplo 1: Análise Rápida de Aeroporto

```r
library(AirportPro)

# Carregar aeroporto
sbpa <- Airport$new(system.file("extdata", "ad_sbpa.json", package = "AirportPro"))

# Ver faixas de pista
print(sbpa$faixas)

# Ver superfícies limitadoras
sbpa$list_superficies()
```

### Exemplo 2: Mapa com Múltiplas Camadas

```r
# Converter geometrias
pistas <- lapply(sbpa$pistas, runway_to_sf)
faixas <- lapply(sbpa$pistas, runway_strip_to_sf)

# Criar mapa base
mapa <- plot_all_runways_leaflet(pistas)

# Adicionar faixas
for (faixa in faixas) {
  mapa <- add_to_map(mapa, faixa, color = "#FFD700", opacity = 0.3)
}

# Visualizar
mapa
```

### Exemplo 3: Exportar para GeoJSON

```r
library(sf)

# Converter pista para sf
pista_sf <- runway_to_sf(sbpa$pistas[[1]])

# Exportar para GeoJSON
st_write(pista_sf, "pista_sbpa.geojson")
```

## Estrutura do Pacote

```
AirportPro/
├── R/                          # Código-fonte R
│   ├── classR6_Airport.R       # Classe principal
│   ├── get_superficie_params.R # Cálculo de superfícies ICA 11-408
│   ├── get_strip_params.R      # Cálculo de faixas RBAC-154
│   ├── runway_to_sf.R          # Conversão espacial
│   └── plot_*.R                # Funções de visualização
├── man/                        # Documentação (roxygen2)
├── inst/
│   ├── extdata/                # Dados de exemplo (JSON)
│   ├── schemas/                # Schemas de validação
│   ├── normas/                 # Documentação das normas
│   └── reports/                # Templates de relatórios
└── docs/                       # Site pkgdown
```

## Recursos Adicionais

- **Documentação Completa**: [username.github.io/AirportPro](https://username.github.io/AirportPro)
- **Reportar Problemas**: [GitHub Issues](https://github.com/username/AirportPro/issues)
- **Schema JSON**: `inst/schemas/aeroporto-1.0.1.json`
- **Dados Normativos**: `inst/extdata/ica_11_408_tabela_4_3_dados_v1.0.0.json`

## Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/NovaFuncionalidade`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## Autor

**Guterres**
📧 email@example.com

## Citação

Se você utilizar este pacote em trabalhos acadêmicos ou técnicos, por favor cite:

```
Guterres (2025). AirportPro: Análise Profissional de Aeroportos e Pistas.
R package version 1.0.1. https://github.com/username/AirportPro
```

## Referências Normativas

- **RBAC-154** — Regulamento Brasileiro da Aviação Civil nº 154 (ANAC, 2019)
  *Projeto de Aeródromos*

- **ICA 11-408** — Instrução do Comando da Aeronáutica nº 11-408 (DECEA)
  *Plano Básico de Zona de Proteção de Aeródromos*

---

**Desenvolvido com ❤️ para a aviação civil brasileira**
