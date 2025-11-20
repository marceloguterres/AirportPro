\name{print_runway_diagram}
\alias{print_runway_diagram}
\title{Desenho textual simples da pista e da faixa (strip)}
\usage{
print_runway_diagram(apt, pista_id, width_chars = 60)
}
\arguments{
\item{apt}{Objeto \code{Airport}.}

\item{pista_id}{Identificador da pista (ex: "12/30").}

\item{width_chars}{Largura máxima do desenho, em caracteres (padrão: 60).}
}
\value{
Invisivelmente retorna \code{NULL} após imprimir no console.
}
\description{
Imprime no terminal um diagrama ASCII com a faixa da pista (strip) e, dentro dela, a pista declarada.
}
