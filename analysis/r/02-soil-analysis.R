# Reconstructed from reports/soil-analysis.pdf; full PCA and LDA code.
# Run from the repository root. The fitted LDA scores are in-sample descriptions.
library(ggplot2)
library(MASS)
library(ggplot2)
library(tidyverse)
library(scales)
library(factoextra)
pear_data <- read.csv("data/raw/G12.size.data.csv")
outcome_data <- read.csv("data/raw/G12.outcome.data.csv")
data <- read.csv("data/raw/G12.soil.data.csv")
cols_to_remove <- c("tree_ID", "location", "ecotr_id", "tree_id", "species", "climate")
soil_data <- dplyr::select(data, -all_of(cols_to_remove))
pca_data <- prcomp(soil_data, center = TRUE, scale = TRUE)
fviz_eig(pca_data, addlabels = TRUE)
fviz_pca_biplot(pca_data, repel = FALSE,
geom.ind = "point",
col.var = "#0083FF",
col.ind = data$climate,
labelsize = 3
)
pear_count <- summarise(
group_by(outcome_data, location, ecotr_id, tree_id),
pears = n()
)
soil_with_pears <- left_join(
data,
pear_count,
by = c("location", "ecotr_id", "tree_id")
)
predictors <- dplyr::select(
soil_with_pears,
-tree_ID,
-location,
-ecotr_id,
-tree_id,
-species,
-climate
)
group <- as.factor(data$climate)
predictors_scaled <- scale(predictors)
lda_model <- lda(group ~., data = as.data.frame(predictors_scaled))
lda_result <- predict(lda_model)
lda_scores <- as.data.frame(lda_result$x)
lda_scores$climate <- data$climate
# Extract proportion of between-class variance
lda_var <- lda_model$svd^2
lda_var_ratio <- lda_var / sum(lda_var)
# Barplot of eigenvalues (proportion of variance)
midpoints <- barplot(
lda_var_ratio,
names.arg = paste0("LD", 1:length(lda_var_ratio)),
col = "skyblue",
ylab = "Proportion of Between-Class Variance",
main = "LDA: Eigenvalues",
ylim = c(0, 1),
width = 0.3,
space = 0.5
)
text(
x = midpoints,
y = lda_var_ratio,
labels = paste0(round(lda_var_ratio * 100, 1), "%"),
pos = 3,
cex = 0.9
)
# LDA scatter plot
ggplot(lda_scores, aes(x = LD1, y = LD2, color = as.factor(climate))) +
geom_point(size = 3, alpha = 0.8) +
labs(
title = "LDA Scatter Plot (LD1 vs LD2)",
x = "LD1",
y = "LD2",
color = "Climate Scenario"
) +
theme_minimal(base_size = 12)
# LD1 contributions
ld1_loadings <- lda_model$scaling[, 1]
loading_df <- data.frame(
Variable = names(ld1_loadings),
LD1 = ld1_loadings
)
loading_df$Color <- ifelse(loading_df$LD1 < 0, "lightcoral", "skyblue")
loading_df <- mutate(loading_df, Variable = fct_reorder(Variable, abs(LD1)))
ggplot(loading_df, aes(x = Variable, y = LD1, fill = Color)) +
geom_col() +
geom_text(
aes(label = round(LD1, 1)),
hjust = ifelse(loading_df$LD1 > 0, -0.2, 1.2)
) +
scale_fill_identity() +
coord_flip() +
labs(
title = "LDA Variable Contributions (LD1)",
x = "Variable",
y = "Coefficient (Loading on LD1)"
) +
theme_minimal(base_size = 12)

write.csv(data.frame(component = seq_along(pca_data$sdev), eigenvalue = pca_data$sdev^2, proportion = pca_data$sdev^2 / sum(pca_data$sdev^2)), "results/pca-variance-r.csv", row.names = FALSE)
write.csv(lda_scores, "results/lda-scores-r.csv", row.names = FALSE)
