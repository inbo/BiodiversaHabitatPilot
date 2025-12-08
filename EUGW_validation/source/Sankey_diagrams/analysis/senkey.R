# senkey diagram

## pairwise transition matrix between years
# prepare empty list
pairwise_list <- vector("list", nlyr(r_stack) - 1)

# loop, which extracts pairwise trtansition matrix
# each time starting year is selected and compared to year+1
for (i in 1:(nlyr(r_stack) - 1)) {
  r_from <- r_stack[[i]]
  r_to   <- r_stack[[i + 1]]
  
  # twin raster is created
  rr <- c(r_from, r_to)
  names(rr) <- c("from_class", "to_class")
  
  # extract possible cell values combinations, drop NA
  df <- terra::as.data.frame(rr, na.rm = TRUE)
  
  # in case of EUGW, we are only interested in valuse from 21 to 27 (anyway there are no other values, except NA)
  df <- df |>
    filter(from_class %in% 21:27, to_class %in% 21:27)
  
  # lets count number of pixels in each transition category
  ct <- df |>
    count(from_class, to_class, name = "count") |>
    mutate(year_from = names(r_stack)[i],
           year_to   = names(r_stack)[i + 1])
  
  pairwise_list[[i]] <- ct
  
  # rubbish, gc
  rm(r_from, r_to, rr, df, ct)
  gc()
}

transitions_df <- bind_rows(pairwise_list)
rm(pairwise_list)

## create NODES and LINKS for sankey diagram
# names
src_names <- paste0(transitions_df$year_from, "_", transitions_df$from_class)
tgt_names <- paste0(transitions_df$year_to,   "_", transitions_df$to_class)

node_names <- unique(c(src_names, tgt_names))

# df for nodes
nodes <- data.frame(name = node_names, stringsAsFactors = FALSE)
nodes$year  <- as.integer(substr(nodes$name, 1, 4))
nodes$class <- as.integer(sub(".*_(\\d+)$", "\\1", nodes$name))

# sort: year ascending, class 21→27 (but some of them are absent)
desired_order <- 21:27
nodes$class_rank <- match(nodes$class, desired_order) # define desired order of classes within nodes df
nodes <- nodes[order(nodes$year, nodes$class_rank, nodes$class), ] # sort
nodes$id <- seq_len(nrow(nodes)) - 1

nodes$node_group <- factor(as.character(nodes$class),
                           levels = as.character(desired_order))
nodes <- nodes[, c("name", "id", "node_group")]

# LINKS
links <- transitions_df |>
  mutate(source_name = paste0(year_from, "_", from_class),
         target_name = paste0(year_to,   "_", to_class)) |>
  left_join(nodes[, c("name","id")], by = c("source_name" = "name")) |>
  rename(source = id) |>
  left_join(nodes[, c("name","id")], by = c("target_name" = "name")) |>
  rename(target = id) |>
  transmute(
    source,
    target,
    count,
    year_from,
    year_to,
    from_class,
    to_class,
    link_group = factor(from_class, levels = desired_order)  # for link color
  )

## limit sankey diagram for better readability

# links
if (min_count_for_links > 0) {
  links <- links |> filter(count >= min_count_for_links) # filter links with lower count than x
}

# nodes
if (min_count_for_nodes > 0) {
  # compute count for each nod
  node_strength <- links %>%
    group_by(source) %>%
    summarise(total_out = sum(count), .groups = "drop") %>%
    full_join(
      links %>% group_by(target) %>%
        summarise(total_in = sum(count), .groups = "drop"),
      by = c("source" = "target")
    ) %>%
    mutate(id = source,
           total = rowSums(across(c(total_out, total_in)), na.rm = TRUE)) %>%
    dplyr::select(id, total)
  
  keep_nodes <- node_strength %>%
    filter(total >= min_count_for_nodes) %>%
    pull(id)
  
  # filter nodes and their links
  nodes <- nodes %>% filter(id %in% keep_nodes)
  links <- links %>% filter(source %in% keep_nodes, target %in% keep_nodes)
  
  # resample IDs
  id_map <- setNames(seq_len(nrow(nodes)) - 1, nodes$id)
  nodes$id <- unname(id_map[as.character(nodes$id)])
  links$source <- unname(id_map[as.character(links$source)])
  links$target <- unname(id_map[as.character(links$target)])
}

# colors
class_levels <- as.character(desired_order)
palette_classes <- c("#f5ca7a", "#a5f57a", "#7ab6f5", "#ca7af5", "#5c8944", "#f57a7a", "#895a44")
palette_classes <- rep(palette_classes, length.out = length(class_levels)) # if more classes than colors

colourScale_js <- htmlwidgets::JS(
  sprintf(
    "d3.scaleOrdinal().domain(%s).range(%s)",
    jsonlite::toJSON(class_levels),
    jsonlite::toJSON(palette_classes)
  )
)

# sankey creation
sankey <- networkD3::sankeyNetwork(
  Links = links,
  Nodes = nodes,
  Source = "source",
  Target = "target",
  Value  = "count",
  NodeID = "name",
  NodeGroup = "node_group",   # NODES: color = group
  LinkGroup = "link_group",   # LINKS: color = group of source
  colourScale = colourScale_js,
  fontSize = 12,
  nodeWidth = 26,
  nodePadding = 10,
  sinksRight = FALSE,
  iterations = 0 # !!! to keep desired order
)


# plot and save

sankey

saveWidget(sankey, file = file.path(dir_out, "sankey_diagram.html"), selfcontained = F)
cat(paste0("DONE, diagram saved to ", file.path(dir_out, "sankey_diagram.html"), "\n"))

