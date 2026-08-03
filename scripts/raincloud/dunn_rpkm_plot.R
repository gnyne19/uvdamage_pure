library(data.table)
library(ggplot2)
library(rstatix)
library(ggsignif)
library(ggrain)


atac_64_file <- "C:/pure_project/ATAC_64_rpkm.tsv"
atac_cpd_file <- "C:/pure_project/ATAC_CPD_rpkm.tsv"

h3k9_64_file <- "C:/pure_project/H3K9me3_64_rpkm.tsv"
h3k9_cpd_file <- "C:/pure_project/H3K9me3_CPD_rpkm.tsv"

h3k27_64_file <- "C:/pure_project/H3K27me3_64_rpkm.tsv"
h3k27_cpd_file <- "C:/pure_project/H3K27me3_CPD_rpkm.tsv"

output_folder <- "C:/pure_project"


atac_64 <- fread(
  atac_64_file,
  header = TRUE,
  sep = "\t"
)

atac_cpd <- fread(
  atac_cpd_file,
  header = TRUE,
  sep = "\t"
)

h3k9_64 <- fread(
  h3k9_64_file,
  header = TRUE,
  sep = "\t"
)

h3k9_cpd <- fread(
  h3k9_cpd_file,
  header = TRUE,
  sep = "\t"
)

h3k27_64 <- fread(
  h3k27_64_file,
  header = TRUE,
  sep = "\t"
)

h3k27_cpd <- fread(
  h3k27_cpd_file,
  header = TRUE,
  sep = "\t"
)


print(head(atac_64))
print(head(atac_cpd))

print(dim(atac_64))
print(dim(atac_cpd))
print(dim(h3k9_64))
print(dim(h3k9_cpd))
print(dim(h3k27_64))
print(dim(h3k27_cpd))


prepare_peak_data <- function(
    atac,
    h3k9,
    h3k27,
    rpkm_column
) {
  
  plot_data <- data.frame(
    chromatin = c(
      rep("ATAC", nrow(atac)),
      rep("H3K9me3", nrow(h3k9)),
      rep("H3K27me3", nrow(h3k27))
    ),
    
    rpkm = c(
      as.numeric(atac[[rpkm_column]]),
      as.numeric(h3k9[[rpkm_column]]),
      as.numeric(h3k27[[rpkm_column]])
    )
  )
  
  # Remove missing and infinite values
  plot_data <- plot_data[
    !is.na(plot_data$rpkm) &
      is.finite(plot_data$rpkm),
  ]
  
  # Set the group order
  plot_data$chromatin <- factor(
    plot_data$chromatin,
    levels = c(
      "ATAC",
      "H3K9me3",
      "H3K27me3"
    )
  )
  
  return(plot_data)
}


get_dunn_result <- function(
    dunn_result,
    first_group,
    second_group
) {
  
  selected_row <- dunn_result[
    (
      dunn_result$group1 == first_group &
        dunn_result$group2 == second_group
    ) |
      (
        dunn_result$group1 == second_group &
          dunn_result$group2 == first_group
      ),
  ]
  
  return(selected_row)
}


calculate_median_difference <- function(
    plot_data,
    first_group,
    second_group
) {
  
  first_median <- median(
    plot_data$rpkm[
      plot_data$chromatin == first_group
    ],
    na.rm = TRUE
  )
  
  second_median <- median(
    plot_data$rpkm[
      plot_data$chromatin == second_group
    ],
    na.rm = TRUE
  )
  
  return(first_median - second_median)
}


make_raincloud <- function(
    plot_data,
    plot_title,
    y_label,
    y_limit
) {
  
  # Run Dunn post-hoc comparisons
  dunn_result <- rstatix::dunn_test(
    data = plot_data,
    formula = rpkm ~ chromatin,
    p.adjust.method = "BH"
  )
  
  atac_h3k9_dunn <- get_dunn_result(
    dunn_result,
    "ATAC",
    "H3K9me3"
  )
  
  atac_h3k27_dunn <- get_dunn_result(
    dunn_result,
    "ATAC",
    "H3K27me3"
  )
  
  h3k9_h3k27_dunn <- get_dunn_result(
    dunn_result,
    "H3K9me3",
    "H3K27me3"
  )
  
  ordered_dunn_results <- rbind(
    atac_h3k9_dunn,
    atac_h3k27_dunn,
    h3k9_h3k27_dunn
  )
  
  median_differences <- c(
    calculate_median_difference(
      plot_data,
      "ATAC",
      "H3K9me3"
    ),
    calculate_median_difference(
      plot_data,
      "ATAC",
      "H3K27me3"
    ),
    calculate_median_difference(
      plot_data,
      "H3K9me3",
      "H3K27me3"
    )
  )
  
  ordered_dunn_results$median_difference <- median_differences
  
  peak_counts <- table(
    plot_data$chromatin
  )
  
  x_labels <- c(
    "ATAC" = paste0(
      "ATAC\nn = ",
      peak_counts["ATAC"]
    ),
    "H3K9me3" = paste0(
      "H3K9me3\nn = ",
      peak_counts["H3K9me3"]
    ),
    "H3K27me3" = paste0(
      "H3K27me3\nn = ",
      peak_counts["H3K27me3"]
    )
  )
  
  comparisons <- list(
    c("ATAC", "H3K9me3"),
    c("ATAC", "H3K27me3"),
    c("H3K9me3", "H3K27me3")
  )
  
  significance_annotations <- ordered_dunn_results$p.adj.signif
  
  median_annotation_data <- data.frame(
    x = c(
      1.5,
      2.0,
      2.5
    ),
    y = c(
      y_limit * 1.10,
      y_limit * 1.30,
      y_limit * 1.50
    ),
    label = paste0(
      "\u0394med = ",
      format(
        round(
          ordered_dunn_results$median_difference,
          4
        ),
        nsmall = 4
      )
    )
  )
  
  # Filter only the displayed data
  plot_data_filtered <- subset(
    plot_data,
    rpkm >= 0 &
      rpkm <= y_limit
  )
  
  chromatin_colors <- c(
    "ATAC" = "#d62828",
    "H3K9me3" = "#003049",
    "H3K27me3" = "#f77f00"
  )
  
  significance_legend <- paste0(
    "BH-adjusted p-values: ",
    "ns \u2265 0.05   ",
    "* < 0.05   ",
    "** < 0.01   ",
    "*** < 0.001   ",
    "**** < 0.0001\n",
    "\u0394med = first group median \u2212 second group median"
  )
  
  plot_object <- ggplot(
    plot_data_filtered,
    aes(
      x = chromatin,
      y = rpkm,
      fill = chromatin,
      colour = chromatin
    )
  ) +
    
    ggrain::geom_rain(
      rain.side = "r",
      seed = 42,
      
      point.args = list(
        alpha = 0,
        size = 0
      ),
      
      boxplot.args = list(
        outlier.shape = NA,
        alpha = 0.55,
        width = 0.14
      ),
      
      boxplot.args.pos = list(
        position = ggplot2::position_nudge(
          x = 0
        )
      ),
      
      violin.args = list(
        alpha = 0.55,
        width = 0.8,
        trim = TRUE,
        colour = NA
      ),
      
      violin.args.pos = list(
        position = ggplot2::position_nudge(
          x = 0.16
        )
      )
    ) +
    
    geom_jitter(
      aes(
        x = as.numeric(chromatin) - 0.22
      ),
      width = 0.08,
      height = 0,
      size = 0.25,
      alpha = 0.25
    ) +
    
    ggsignif::geom_signif(
      comparisons = comparisons,
      annotations = significance_annotations,
      y_position = c(
        y_limit * 1.1,
        y_limit * 1.3,
        y_limit * 1.5
      ),
      tip_length = 0.01,
      textsize = 3.6,
      vjust = 0
    ) +
    
    geom_text(
      data = median_annotation_data,
      aes(
        x = x,
        y = y,
        label = label
      ),
      inherit.aes = FALSE,
      size = 3.0,
      colour = "black"
    ) +
    
    scale_fill_manual(
      values = chromatin_colors
    ) +
    
    scale_colour_manual(
      values = chromatin_colors
    ) +
    
    scale_x_discrete(
      labels = x_labels
    ) +
    
    coord_cartesian(
      ylim = c(
        0,
        y_limit * 1.68
      ),
      clip = "off"
    ) +
    
    theme_classic() +
    
    labs(
      title = plot_title,
      subtitle = "Dunn's post-hoc test",
      caption = significance_legend,
      x = "Chromatin region",
      y = y_label
    ) +
    
    theme(
      plot.title = element_text(
        hjust = 0.5,
        size = 14
      ),
      plot.subtitle = element_text(
        hjust = 0.5,
        size = 10
      ),
      plot.caption = element_text(
        hjust = 0.5,
        size = 7.2,
        lineheight = 1.2
      ),
      axis.title = element_text(
        size = 12
      ),
      axis.text = element_text(
        size = 11
      ),
      legend.position = "none",
      plot.margin = margin(
        t = 15,
        r = 10,
        b = 20,
        l = 10
      )
    )
  
  cat("\n", plot_title, "\n")
  cat("Dunn post-hoc tests:\n")
  
  print(
    ordered_dunn_results[
      ,
      c(
        "group1",
        "group2",
        "statistic",
        "p",
        "p.adj",
        "p.adj.signif",
        "median_difference"
      )
    ]
  )
  
  cat("\nPeak counts:\n")
  print(peak_counts)
  
  return(plot_object)
}


cpd_real_data <- prepare_peak_data(
  atac = atac_cpd,
  h3k9 = h3k9_cpd,
  h3k27 = h3k27_cpd,
  rpkm_column = "real_rpkm"
)

cpd_sim_data <- prepare_peak_data(
  atac = atac_cpd,
  h3k9 = h3k9_cpd,
  h3k27 = h3k27_cpd,
  rpkm_column = "sim_rpkm"
)

pp64_real_data <- prepare_peak_data(
  atac = atac_64,
  h3k9 = h3k9_64,
  h3k27 = h3k27_64,
  rpkm_column = "real_rpkm"
)

pp64_sim_data <- prepare_peak_data(
  atac = atac_64,
  h3k9 = h3k9_64,
  h3k27 = h3k27_64,
  rpkm_column = "sim_rpkm"
)


cpd_real_plot <- make_raincloud(
  plot_data = cpd_real_data,
  plot_title = "CPD Real Damage RPKM per Peak",
  y_label = "Real RPKM",
  y_limit = 2
)

print(cpd_real_plot)


cpd_sim_plot <- make_raincloud(
  plot_data = cpd_sim_data,
  plot_title = "CPD Simulated Damage RPKM per Peak",
  y_label = "Simulated RPKM",
  y_limit = 2
)

print(cpd_sim_plot)


pp64_real_plot <- make_raincloud(
  plot_data = pp64_real_data,
  plot_title = "6-4PP Real Damage RPKM per Peak",
  y_label = "Real RPKM",
  y_limit = 4
)

print(pp64_real_plot)


pp64_sim_plot <- make_raincloud(
  plot_data = pp64_sim_data,
  plot_title = "6-4PP Simulated Damage RPKM per Peak",
  y_label = "Simulated RPKM",
  y_limit = 2
)

print(pp64_sim_plot)


ggsave(
  filename = file.path(
    output_folder,
    "dunn_CPD_real_peak_raincloud.png"
  ),
  plot = cpd_real_plot,
  width = 7,
  height = 6,
  dpi = 300
)

ggsave(
  filename = file.path(
    output_folder,
    "dunn_CPD_sim_peak_raincloud.png"
  ),
  plot = cpd_sim_plot,
  width = 7,
  height = 6,
  dpi = 300
)

ggsave(
  filename = file.path(
    output_folder,
    "dunn_64PP_real_peak_raincloud.png"
  ),
  plot = pp64_real_plot,
  width = 7,
  height = 6,
  dpi = 300
)

ggsave(
  filename = file.path(
    output_folder,
    "dunn_64PP_sim_peak_raincloud.png"
  ),
  plot = pp64_sim_plot,
  width = 7,
  height = 6,
  dpi = 300
)
