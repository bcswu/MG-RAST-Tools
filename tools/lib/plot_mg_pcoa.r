# This script uses matR to generate 2 or 3 dimmensional pcoas

# table_in is the abundance array as tab text -- columns are samples(metagenomes) rows are taxa or functions
# color_table and pch_table are tab tables, with each row as a metagenome, each column as a metadata 
# grouping/coloring. These tables are used to define colors and point shapes for the plot
# It is assumed that the order of samples (left to right) in table_in is the same
# as the order (top to bottom) in color_table and pch_table

# basic operation is to produce a color-less pcoa of the input data

# user can also input a table to specify colors
# This table can contain colors (as hex or nominal) or can contain metadata
# that is automatically interpreted to produce coloring (identical values or text receive the same color
# 
# The user can also input a pch table -- this is more advanced R plotting that allows them to 
# select the shape of the plotted points
#
# example invocations are below - going from simplest to most elaborate

# create a 3d plot, minimum input arguments:
#   plot_mg_pcoa(table_in="test_data.txt")

# create a 2d plot, minimum input arguments:
#   plot_mg_pcoa(table_in="test_data.txt", plot_pcs = c(1,2))

# create a 3d plot with colors specified by a color_table file 
# (by default, first column of color table is used) and the script expecpts
# entries to be literal or hex colors:
#   plot_mg_pcoa(table_in="test_data.txt", color_table="test_colors.txt")

# create a 3d plot with colors generated from the color_table, using second column in color table
# specify option to generate colors from the table (any metadata will work)
# specify that the second column is used:
#   plot_mg_pcoa(table_in="test_data.txt", color_table="test_colors.txt", auto_colors=TRUE, color_column=2)

# create a plot where every input argument is explicitly addressed:
#   plot_mg_pcoa(table_in="test_data.txt", image_out = "wacky_pcoa", plot_pcs = c(1,3,5), label_points=NA, color_table="test_colors.txt", auto_colors=TRUE, color_column=3, pch_table="test_pch.txt", pch_column=3, image_width_in=10, image_height_in=10, image_res_dpi=250)

plot_mg_pcoa <<- function(
                          table_in="", # annotation abundance table (raw or normalized values)
                          image_out="default",
                          plot_pcs=c(1,2,3), # R formated string telling which coordinates to plot, and how many (2 or 3 coordinates)
                          dist_metric="euclidean", # distance metric to use one of (bray-curtis, euclidean, maximum, manhattan, canberra, minkowski, difference)
                          label_points=FALSE, # default is off
                          color_list=NA, # a list of colors for data points
                          color_table=NA, # matrix that contains colors or metadata that can be used to generate colors
                          color_column=1, # column of the color matrix to color the pcoa (colors for the points in the matrix) -- rows = samples, columns = colorings
                          auto_colors=FALSE, # automatically generate colors from metadata tables (identical values/text get the same color)
                          pch_list=NA, # a list of shapes for data points
                          pch_table=NA, # additional matrix that allows users to specify the shape of the data points
                          pch_column=1,
                          image_width_in=11,
                          image_height_in=8.5,
                          image_res_dpi=300
                          )
  
{
  
  require(matR)


      
  
  ###################################################################################################################################  
  # MAIN
  ###################################################################################################################################
  # generate filename for the image output
  if ( identical(image_out, "default") ){
    image_out = paste(table_in, ".pcoa.png", sep="", collapse="")
  }else{
    image_out = paste(image_out, ".png", sep="", collapse="")
  }
  ###################################################################################################################################
  
  ###################################################################################################################################
  ######## import/parse all inputs
  
  # import DATA the data (from tab text)
  data_matrix <- data.matrix(read.table(table_in, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
  
  # convert data to a matR collection
  data_collection <- suppressWarnings(as(data_matrix, "collection")) # take the input data and create a matR object with it
  
  # import colors if the option is selected - generate colors from metadata table if that option is selected
  if ( identical( is.na(color_table), FALSE ) ){
    color_matrix <- as.matrix(read.table(file=color_table, row.names=1, header=TRUE, sep="\t", colClasses = "character", check.names=FALSE, comment.char = "", quote="", fill=TRUE, blank.lines.skip=FALSE))
    # generate auto colors if the color matrix contains metadata and not colors
    # this needs more work -- to get legend that maps colors to groups
    if ( identical(auto_colors, TRUE) ){
      pcoa_colors <- create_colors(color_matrix, color_mode="auto")

      # generate figure legend (for auto-coloring only)
      png(
          filename = paste(image_out, ".legend.png", sep="", collapse=""),
          width = 3,
          height = 8,
          res = 300,
          units = 'in'
          )
      
      # this bit is a repeat of the code in the sub below - clean up later
      column_factors <- as.factor(color_matrix[,color_column])
      column_levels <- levels(as.factor(color_matrix[,color_column]))
      num_levels <- length(column_levels)
      color_levels <- col.wheel(num_levels)
      #levels(column_factors) <- color_levels
      #my_data.color[,color_column]<-as.character(column_factors)

      par( mai = c(0,0,0,0) )
      par( oma = c(0,0,0,0) )
      plot.new()
      par_legend <- par_fetch()

      par_legend.test <<- par_legend
      
      par_legend_cex <- calculate_cex(column_levels, par_legend$my_pin, par_legend$my_mai, reduce_by=0.40)

      par_legend_cex.test <<- par_legend_cex
      
      ## legend_len <- length(color_levels)
      ## cex_val <- 1.0
      ## if (legend_len > 5) {
      ##     cex_val <- 0.7
      ## }
      ## if (legend_len > 20) {
      ##       cex_val <- 0.5
      ## }
      ## if (legend_len > 50) {
      ##       cex_val <- 0.3
      ## }

      legend( x="center", legend=column_levels, pch=16, col=color_levels, cex=par_legend_cex )
      
      dev.off()
    }else{
      pcoa_colors <- color_matrix
    }
    plot_colors <- pcoa_colors[,color_column]
    #plot_colors <- pcoa_colors[,color_column,drop=FALSE]
    #plot_colors <- plot_colors[ colnames(data_matrix),,drop=FALSE ]

    
    plot_colors.test <<- plot_colors
  }else{
    # use color list if the option is selected
    if ( identical( is.na(color_list), FALSE ) ){
      plot_colors <- color_list
    }else{
      plot_colors <- "black"
    }
  }

  # load pch matrix if one is specified
  if ( identical( is.na(pch_table), FALSE ) ){
    pch_matrix <- data.matrix(read.table(file=pch_table, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
    plot_pch <- pch_matrix[,pch_column]
  }else{
    # use pch list if the option is selected
    if ( identical( is.na(pch_list), FALSE ) ){
      plot_pch <- pch_list
    }else{
      plot_pch = 16
    }
  }
      
  ###################################################################################################################################

  ###################################################################################################################################
  # GENERATE THE PLOT - A SCOND LEGEND FIGURE IS PRODUCED IF AU
  # Have matR calculate the pco and generate an image generate the image (2d)
  png(
      filename = image_out,
      width = image_width_in,
      height = image_height_in,
      res = image_res_dpi,
      units = 'in'
    )
  
  # 2d (color variable in matR is called "col")
  if( length(plot_pcs)==2 ){
    # with labels
    if( identical(label_points, TRUE) ){
      matR::pco(data_collection, comp = plot_pcs, method = dist_metric, col = plot_colors, pch = plot_pch)
    }else{
    # without labels
      matR::pco(data_collection, comp = plot_pcs, method = dist_metric,  col = plot_colors, pch = plot_pch, labels=NA)
    }
  }

  # 3d (color variable in matR is called "color"
  if( length(plot_pcs)==3 ){
    # with labels
    if( identical(label_points, TRUE) ){
      pco(data_collection, comp = plot_pcs, method = dist_metric, color = plot_colors, pch = plot_pch)
    }else{
    # without labels
      pco(data_collection, comp = plot_pcs, method = dist_metric, color = plot_colors, pch = plot_pch, labels=NA)
    }
  }

 dev.off()

  
  
}
###################################################################################################################################

###################################################################################################################################


###################################################################################################################################
######## SUBS

############################################################################
### Color methods adapted from https://stat.ethz.ch/pipermail/r-help/2002-May/022037.html
############################################################################
# create optimal contrast color selection using a color wheel
col.wheel <- function(num_col, my_cex=0.75) {
  cols <- rainbow(num_col)
  col_names <- vector(mode="list", length=num_col)
  for (i in 1:num_col){
    col_names[i] <- getColorTable(cols[i])
  }
  cols
}

# $ # The inverse function to col2rgb()
rgb2col <- function(rgb) {
  rgb <- as.integer(rgb)
  class(rgb) <- "hexmode"
  rgb <- as.character(rgb)
  rgb <- matrix(rgb, nrow=3)
  paste("#", apply(rgb, MARGIN=2, FUN=paste, collapse=""), sep="")
}

# $ # Convert all colors into format "#rrggbb"
getColorTable <- function(col) {
  rgb <- col2rgb(col);
  col <- rgb2col(rgb);
  sort(unique(col))
}
############################################################################

create_colors <- function(color_matrix, color_mode = "auto"){ # function to automtically generate colors from metadata with identical text or values    
  my_data.color <- data.frame(color_matrix)
  ids <- rownames(color_matrix)
  color_categories <- colnames(color_matrix)
  for ( i in 1:dim(color_matrix)[2] ){
    column_factors <- as.factor(color_matrix[,i])
    column_levels <- levels(as.factor(color_matrix[,i]))
    num_levels <- length(column_levels)
    color_levels <- col.wheel(num_levels)
    levels(column_factors) <- color_levels
    my_data.color[,i]<-as.character(column_factors)
  }
  return(my_data.color)
}
############################################################################
############################################################################

############################################################################
### SUB: Sub to provide scaling for title and legened cex
############################################################################
calculate_cex <- function(my_labels, my_pin, my_mai, reduce_by=0.30, debug){
  
  # get figure width and height from pin
  my_width <- my_pin[1]
  my_height <- my_pin[2]
  
  # get margine from mai
  my_margin_bottom <- my_mai[1]
  my_margin_left <- my_mai[2]
  my_margin_top <- my_mai[3]
  my_margin_right <- my_mai[4]
  
  #if(debug==TRUE){
  #  print(paste("my_pin: ", my_pin, sep=""))
  #  print(paste("my_mai: ", my_mai, sep=""))
  #}
  
  # find the longest label (in inches), and figure out the maximum amount of length scaling that is possible
  label_width_max <- 0
  for (i in 1:length(my_labels)){  
    label_width <- strwidth(my_labels[i],'inches')
    if ( label_width > label_width_max){ label_width_max<-label_width  }
  }
  label_width_scale_max <- ( my_width - ( my_margin_right + my_margin_left ) )/label_width_max
  ## if(debug==TRUE){ 
  ##                 cat(paste("\n", "my_width: ", my_width, "\n", 
  ##                           "label_width_max: ", label_width_max, "\n",
  ##                           "label_width_scale_max: ", label_width_scale_max, "\n",
  ##                           sep=""))  
  ##                 }
  
  
  # find the number of labels, and figure out the maximum height scaling that is possible
  label_height_max <- 0
  for (i in 1:length(my_labels)){  
    label_height <- strheight(my_labels[i],'inches')
    if ( label_height > label_height_max){ label_height_max<-label_height  }
  }
  adjusted.label_height_max <- ( label_height_max + label_height_max*0.4 ) # fudge factor for vertical space between legend entries
  label_height_scale_max <- ( my_height - ( my_margin_top + my_margin_bottom ) ) / ( adjusted.label_height_max*length(my_labels) )
  ## if(debug==TRUE){ 
  ##                 cat(paste("\n", "my_height: ", my_height, "\n", 
  ##                           "label_height_max: ", label_height_max, "\n", 
  ##                           "length(my_labels): ", length(my_labels), "\n",
  ##                           "label_height_scale_max: ", label_height_scale_max, "\n",
  ##                           sep="" )) 
  ##                 }
  
  # max possible scale is the smaller of the two 
  scale_max <- min(label_width_scale_max, label_height_scale_max)
  # adjust by buffer
  #scale_max <- scale_max*(100-buffer/100) 
  adjusted_scale_max <- ( scale_max * (1-reduce_by) )
  #if(debug==TRUE){ print(cat("\n", "adjusted_scale_max: ", adjusted_scale_max, "\n", sep=""))  }
  return(adjusted_scale_max)
  
}

##################################################################
##################################################################

##################################################################
### SUB(3): Fetch par values of the current frame - use to scale cex
##################################################################
par_fetch <- function(){
    my_pin<-par('pin')
    my_mai<-par('mai')
    my_mar<-par('mar')
    return(list("my_pin"=my_pin, "my_mai"=my_mai, "my_mar"=my_mar))    
}
##################################################################
##################################################################
