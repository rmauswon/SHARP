% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_opt_hclust.R
\name{get_opt_hclust}
\alias{get_opt_hclust}
\title{get the optimal hierarchical clustering results with the optimal number of clusters}
\usage{
get_opt_hclust(mat, hmethod, N.cluster, minN.cluster, maxN.cluster, sil.thre,
  height.Ntimes)
}
\arguments{
\item{mat}{either a feature matrix or a similarity matrix derived from the single-cell expression matrix}

\item{hmethod}{agglomeration method for hierarchical clustering, the default is 'ward.D'. Certainly, some other methods can also be used, like 'ward.D2', 'single', 'complete', 'average' (= UPGMA), 'mcquitty' (= WPGMA), 'median' (= WPGMC) or 'centroid' (= UPGMC).}

\item{minN.cluster}{minimum number of clusters to be tested, the default is 2.}

\item{maxN.cluster}{maximum number of clusters to be tested, the default is 40 or equal to the number of cells (within the specific clustering problem) minus 1, whichever is smaller.}

\item{sil.thre}{the threshold for the maximum Silhouette index (msil), the default is 0.35. If msil < sil.thre, we should use CH index.}

\item{height.Ntimes}{the threshold for the height difference between two adjacent descending-ordered heights obtained after hierarchical clustering. If the height difference is above the threshold, we cut at the median height between the first height and its immediate next which satisfy the criteria.}
}
\value{
a list containing the optimal hierarchical clustering results, the optimal number of clusters, the corresponding maximum Silhouette index and other indices.
}
\description{
This function is to estimate the optimal number of clusters by combining three indices, including Silhouette index, Calinski-Harabasz (CH) index and height difference.
}
\details{
Specifically, we first select the maximum Silhouette index (msil) as the reference. If msil > threshold (here we use sil.thre as the threshold, the default value is 0.35), then its corresponding number of clusters is the optimal; otherwise, we use the maximum CH index as the reference. If the number of clusters with the maximum CH index is not 2, then it is the optimal number of clusters; otherwise, we use the adjacent height difference (which is derived from hierarchical clustering). If the former height is larger than a threshold (Ntimes larger than the immediate latter height), then we cut at the mean height between these two, and the corresponding number of clusters is the optimal one; otherwise, we do not cut.
}
\examples{
hres = get_opt_hclust(mat)

}
