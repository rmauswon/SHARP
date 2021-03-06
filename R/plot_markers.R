#' Plot marker genes
#'
#' This function is to plot a heatmap showing the cluster-specific marker genes. Only the top 10 marker genes for each cluster are shown.
#'
#' @param sginfo the info matrix of selected marker genes, including their correspnding cluster, p-value and AUROC (areas under the curve of the Receiver Operating Characteristic) value.
#'
#' @param scExp the original expression matrix
#'
#' @param label the clustering labels, either using ground-truth labels or predicted clustering results.
#'
#' @param N.marker the maximum number of marker genes selected for each cluster. The default value is 10.
#'
#' @param filename the output file name to save the heatmap figure. By default ,the filename is "markers_heatmap.pdf".
#'
#' @param filetype the type of the output file. Suggested file types are PDF or PNG, while other common types (e.g., JPEG or TIFF) are also acceptable. If not given, the type will be determined as follows: when the number of single cells is less than 5000, the type will be PDF; otherwise, it will be PNG.
#'
#' @return The heatmap of cell-type-specific marker gene expression will be saved into a file (by default the file will be named as "markers_heatmap.pdf" or "markers_heatmap.png", depending on the number of cells). Besides, all of the cluser-specific marker genes and their associated information will be returned.
#'
#' @examples
#'
#' y = SHARP(scExp)
#' sginfo = get_marker_genes(scExp, y)
#' sortmarker = plot_markers(sginfo)
#'
#' @import pheatmap
#'
#' @import RColorBrewer
#'
#' @import data.table
#'
#' @import doParallel
#'
#' @import viridis
#'
#' @import gplots
#'
#' @export
plot_markers <- function(sginfo, label, N.marker, sN.cluster, filename, filetype, nratio, n.cores, width = 900, height = 900, ...){

    if (missing(n.cores)) {
        # number of cores to be used, the default is to use all but one cores
        n.cores = detectCores() - 1
    }
    registerDoParallel(n.cores)
    
    if(missing(label)){
        label = sginfo$label
    }
    
    if(missing(nratio)){#extraction cell ratio when the number of single cells is larger than 1e4
        nratio = 1e4/length(label)
    }
   
    mginfo = sginfo$mginfo
    d = cbind(rownames(mginfo), mginfo)
    colnames(d) = c("genes", colnames(mginfo))
    d = d[order(d$icluster, d$pvalue), ]#sort in ascending order within each icluster

    
    
    sortmarker = d[order(d$icluster, -rank(d$auc), d$pvalue), ]#first cluster, then p-value and then auroc
    
#     sortmarker1 = data.table(sortmarker, key = "icluster")#sort in ascending order


    if(missing(N.marker)){
        N.marker = 10
    }
    nmarker = N.marker
    
    if(missing(sN.cluster)){#number of selected clusters
        sN.cluster = length(unique(mginfo$icluster))
    }
    
    kk = sort(unique(mginfo$icluster))[1:sN.cluster]#the smaller the order of the cluster No, the larger the number of cells in this cluster
    
#     ll = length(unique(sortmarker$icluster))
    ll = sN.cluster
#     y0 = numeric(0)
#     for(i in 1:ll){
#         x = sortmarker[sortmarker$icluster==kk[i], ]#the i-th cluster
#         if(nrow(x) > nmarker){
#             y0 = rbind(y0, x[1:nmarker,])
#         }else{
#             y0 = rbind(y0, x)
#         }
#     }
#     ssmarker = y0
    
    #selected marker genes for showing
    ssmarker = foreach(i = 1:ll, .combine  = rbind)%dopar%{
        x = sortmarker[sortmarker$icluster==kk[i], ]
        x1 = x[1:min(nrow(x), nmarker), ]
        return(x1)
    }
#     ssmarker = sortmarker
#     ssmarker = sortmarker1[, head(.SD, nmarker), by=icluster]#select the top N values in each icluster

    bk <- seq(-2, 2, by=0.01)

#     cc = y$pred_clusters
#     cc0 = which(label %in% kk)
#     cc = label[cc0]
    cc = label
    cellind = order(cc)#order the cells in ascending order
#     if(length(cellind) > 100){
#         d = ceiling(table(cellind)*100/length(cellind))
#         cellind2 = numeric(sum(d))
#         nd = names(d)
#         for(x in nd){
#             x1 = d[x]#times
#             cellind2[which(cellind == x)[1:x1]] = x
#         }
#     }
    
    newc = cc[cellind]

#     if(class(scExp) == "list"){
#          len = scExp
#          dd = foreach(x = 1:len, .combine = "cbind")%dopar%{
#             scExp[[x]][as.character(ssmarker$genes),]
#          }
# #          dd = unlist(sapply(1:len, function(x) scExp[[x]][as.character(ssmarker$genes),]))
#     }else{
#         mat = as.matrix(scExp)
#         sm = mat[as.character(ssmarker$genes), cellind]
#     }
    
    mat = sginfo$mat#expression
    sm = mat[rownames(ssmarker), cellind]#selected marker genes; selected cells
    
    scind = which(newc %in% c(kk))#selected clusters
    newc = newc[scind]
    sm = sm[, scind]
    #if the number of cells is too large
    if(length(cellind) > 1e4){
        kt = ceiling(table(newc)*nratio)
        xu = unique(newc)
        xx = length(xu)
        ki = foreach(i = 1:xx, .combine = c)%dopar%{which(newc == xu[i])[1:kt[i]]}
        sm = sm[, ki]
        newc = newc[ki]
    }

    my = sm
    my = my[apply(my,1,function(x) sd(x)!=0),]
    my <- t(scale(t(my)))
    sm = my
    # 	
    # d=as.dist(1-cor(t(my)))
    # h=hclust(d, method="ward.D")#ward to ward.D
    # dend = as.dendrogram(h)
    # lownum = 1126+1144+176 #(orange, purple, red)
    # wGreen = lownum+1097
    # myorder = c((wGreen+1):4998, (lownum+1):wGreen,1:lownum)
    # myorder = c((wGreen+1):4998, 1:lownum,  (lownum+1):wGreen)
    # dend <- reorder(dend,myorder,agglo.FUN=mean)
	
    # # heatmap.2(as.matrix(sm), Rowv= F, Colv= F, scale="row",trace="none",dendrogram="row", col=colorpanel(length(bk)-1,"blue","white","red"), key=T,keysize=0.7, 
    # # RowSideColors= colorL[ssmarker$icluster], cexCol=1.5,margins=c(28,22), cexRow=1.5)
    # heatmap.2(as.matrix(sm), Rowv= dend, Colv= ssmarker$icluster, scale="row",trace="none",dendrogram="row", col=colorpanel(length(bk)-1,"blue","white","red"), 
    # key=T,keysize=0.7, 
    # RowSideColors= ssmarker$icluster, cexCol=1.5,margins=c(28,22), cexRow=1.5)

    # Data frame with column annotations.
    col_groups = newc
    uc = length(unique(col_groups))
#     print(uc)
    mat_col <- data.frame(cell_type = col_groups)
    k0 = colnames(sm)
    k1 = duplicated(k0)
    nk = length(which(k1))
    if(nk >0){k0[k1] = paste0("d", 1:nk)}
    rownames(mat_col) <- k0

    # List with colors for each annotation.
    mat_colors <- list(cell_type = brewer.pal(uc, "Set1"))
    names(mat_colors$cell_type) <- unique(col_groups)

    #if the file type is not given
    if(missing(filetype)){
        if(length(cellind) < 5000){
            filetype = "pdf"
        }else{
            filetype = "png"
        }
    }
  
     #if the file name is not given
    if(missing(filename)){
        filename = paste0("markers_heatmap.", filetype)
    }
    
    file_plot = filename
    
    if (filetype == "pdf"){
        pdf(file_plot)
    }else if (filetype == "png"){
        png(file_plot, width = width, height = height)
    }
    
    
#     pdf(file_plot,width=6.69, height=6.69)
    
    # inferno(10)#different colors
    pheatmap(
        mat               = sm,
        color             = colorpanel(length(bk)-1,"blue","white","red"),
#         color             = colorpanel(length(bk)-1,"blue", "yellow", "red"),
        border_color      = NA,
        Rowv              = FALSE,
        Colv              = FALSE,
        cluster_rows      = TRUE,
        cluster_cols      = TRUE,
        show_colnames     = FALSE,
        show_rownames     = TRUE,
        annotation_col    = mat_col,
        annotation_colors = mat_colors,
        drop_levels       = TRUE,
        fontsize          = 12,
        scale             = 'column',
    #   kmeans_k          = uc,
        clustering_method = "ward.D",
#         cutree_rows       = uc,
#         cutree_cols       = uc,
        ...
#         main              = "Marker-gene expression matrix"
    )   
    dev.off()
    cat("Marker-genes heatmap saved into", file_plot, "\n")
    
    return(sortmarker)
}

