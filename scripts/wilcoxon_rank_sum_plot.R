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


p_to_significance <- function(p_value) {
  
  if (p_value < 0.0001) {
    return("****")
  }
  
  if (p_value < 0.001) {
    return("***")
  }
  
  if (p_value < 0.01) {
    return("**")
  }
  
  if (p_value < 0.05) {
    return("*")
  }
  
  return("ns")
}


run_wilcox_test <- function(
    plot_data,
    first_group,
    second_group
) {
  
  selected_data <- subset(
    plot_data,
    chromatin %in% c(
      first_group,
      second_group
    )
  )
  
  selected_data$chromatin <- droplevels(
    selected_data$chromatin
  )
  
  test_result <- rstatix::wilcox_test(
    data = selected_data,
    formula = rpkm ~ chromatin,
    paired = FALSE,
    exact = FALSE
  )
  
  first_median <- median(
    selected_data$rpkm[
      selected_data$chromatin == first_group
    ],
    na.rm = TRUE
  )
  
  second_median <- median(
    selected_data$rpkm[
      selected_data$chromatin == second_group
    ],
    na.rm = TRUE
  )
  
  result_row <- data.frame(
    group1 = first_group,
    group2 = second_group,
    median1 = first_median,
    median2 = second_median,
    median_difference = first_median - second_median,
    statistic = test_result$statistic[1],
    p = test_result$p[1]
  )
  
  return(result_row)
}


make_raincloud <- function(
    plot_data,
    plot_title,
    y_label,
    y_limit
) {
  
  atac_h3k9_result <- run_wilcox_test(
    plot_data = plot_data,
    first_group = "ATAC",
    second_group = "H3K9me3"
  )
  
  atac_h3k27_result <- run_wilcox_test(
    plot_data = plot_data,
    first_group = "ATAC",
    second_group = "H3K27me3"
  )
  
  h3k9_h3k27_result <- run_wilcox_test(
    plot_data = plot_data,
    first_group = "H3K9me3",
    second_group = "H3K27me3"
  )
  
  wilcox_results <- rbind(
    atac_h3k9_result,
    atac_h3k27_result,
    h3k9_h3k27_result
  )
  
  wilcox_results$p.adj <- p.adjust(
    wilcox_results$p,
    method = "BH"
  )
  
  wilcox_results$p.adj.signif <- vapply(
    wilcox_results$p.adj,
    p_to_significance,
    character(1)
  )
  
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
  
  significance_annotations <- wilcox_results$p.adj.signif
  
  median_annotation_data <- data.frame(
    x = c(
      1.5,
      2.0,
      2.5
    ),
    y = c(
      y_limit * 1.1,
      y_limit * 1.3,
      y_limit * 1.5
    ),
    label = paste0(
      "Delta median = ",
      format(
        round(
          wilcox_results$median_difference,
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
    "ns >= 0.05   ",
    "* < 0.05   ",
    "** < 0.01   ",
    "*** < 0.001   ",
    "**** < 0.0001\n",
    "Delta median = first group median - second group median"
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
        y_limit * 1.10,
        y_limit * 1.30,
        y_limit * 1.48
      ),
      tip_length = 0.01,
      textsize = 3.6,
      vjust = 0.2
    ) +
    
    geom_text(
      data = median_annotation_data,
      aes(
        x = x,
        y = y,
        label = label
      ),
      inherit.aes = FALSE,
      size = 3.2,
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
        y_limit * 1.55
      ),
      clip = "off"
    ) +
    
    theme_classic() +
    
    labs(
      title = plot_title,
      subtitle = "Wilcoxon rank-sum tests",
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
  
  cat("Wilcoxon rank-sum tests:\n")
  
  print(
    wilcox_results[
      ,
      c(
        "group1",
        "group2",
        "median1",
        "median2",
        "median_difference",
        "statistic",
        "p",
        "p.adj",
        "p.adj.signif"
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
    "CPD_real_peak_raincloud.png"
  ),
  plot = cpd_real_plot,
  width = 7,
  height = 6,
  dpi = 300
)

ggsave(
  filename = file.path(
    output_folder,
    "CPD_sim_peak_raincloud.png"
  ),
  plot = cpd_sim_plot,
  width = 7,
  height = 6,
  dpi = 300
)

ggsave(
  filename = file.path(
    output_folder,
    "64PP_real_peak_raincloud.png"
  ),
  plot = pp64_real_plot,
  width = 7,
  height = 6,
  dpi = 300
)

ggsave(
  filename = file.path(
    output_folder,
    "64PP_sim_peak_raincloud.png"
  ),
  plot = pp64_sim_plot,
  width = 7,
  height = 6,
  dpi = 300
)
