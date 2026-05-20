# Get species pixel counts by EEZ
extract_eez_zonal <- function(id, df, eez_raster, eez_raster_eq, crs) {
  spp_filter <- df %>% filter(aphiaid == id)
  
  if (nrow(spp_filter) == 0) {
    warning("No rows found for aphiaid: ", id)
    return(NULL)
  }
  
  spp <- read_parquet(spp_filter$f) %>%
    mutate(aphiaid = id)
  
  r_spp <- rast(spp, crs = "EPSG:4326") %>%
    extend(ext(eez_raster))

  r_spp_eq <- project(r_spp, crs, method = "near")
  
  cutoff <- mean(spp$cutoff, na.rm = TRUE)
  
  # Create binary layers: 1 if >= cutoff, NA otherwise
  # (zonal sum of 1s = count of cells above cutoff)
  r_binary <- ifel(r_spp_eq[["Current"]]    >= cutoff, 1, NA)
  r_binary45_2050 <- ifel(r_spp_eq[["RCP45_2050"]] >= cutoff, 1, NA)
  r_binary45_2100 <- ifel(r_spp_eq[["RCP45_2100"]] >= cutoff, 1, NA)
  r_binary85_2050 <- ifel(r_spp_eq[["RCP85_2050"]] >= cutoff, 1, NA)
  r_binary85_2100 <- ifel(r_spp_eq[["RCP85_2100"]] >= cutoff, 1, NA)
  
  # Stack and name for clean output
  r_thresh <- c(r_binary, r_binary45_2050, r_binary45_2100,
                r_binary85_2050, r_binary85_2100)
  names(r_thresh) <- c("n_current", "n_RCP45_2050", "n_RCP45_2100",
                       "n_RCP85_2050", "n_RCP85_2100")
  
  # zonal() sums the binary layers within each EEZ zone
  result <- zonal(r_thresh, eez_raster_eq, fun = "sum", na.rm = TRUE)
  
  # eez_raster zones are numeric IDs — join back to EEZ names
  result %>%
    #left_join(eez_zone_lookup, by = "GEONAME") %>%
    # add aphiaid to track each species
    mutate(aphiaid = id) %>% 
    filter(!if_all(c(n_current, n_RCP45_2050, n_RCP45_2100,
                     n_RCP85_2050, n_RCP85_2100), is.na))
}

# Get entry pixels for a species by EEZ
extract_eez_entry_pixels_df <- function(id, df, s, eez_spp_entry, eez_raster_df) {
  spp_filter <- df %>% filter(aphiaid == id)
  
  if (nrow(spp_filter) == 0) {
    warning("No rows found for aphiaid: ", id)
    return(NULL)
  }
  
  spp <- read_parquet(spp_filter$f) %>%
    mutate(aphiaid = id) %>% 
    dplyr::select(x, y, Current, all_of(s), cutoff)
  
  # Filter the df of entry into for this species & scenario
  entry_spp_df <- eez_spp_entry %>% 
    filter(aphiaid == id) %>% 
    filter(scenario == s)
  
  # Get the EEZs for which the species & scenario is entry
  spp_entry_eezs <- unique(entry_spp_df$GEONAME)
  
  # Join the eez dataframe and filter for the spp_entry_eezs
  spp_eez <- inner_join(spp, eez_raster_df) %>% 
    filter(GEONAME %in% spp_entry_eezs) %>% 
    filter(.data[[s]] >= cutoff) %>% 
    mutate(binary = 1) %>% 
    bind_rows()
  
  return(spp_eez)
}

# Get exit pixels for a species by EEZ
extract_eez_exit_pixels_df <- function(id, df, s, eez_spp_exit, eez_raster_df) {
  spp_filter <- df %>% filter(aphiaid == id)
  
  if (nrow(spp_filter) == 0) {
    warning("No rows found for aphiaid: ", id)
    return(NULL)
  }
  
  spp <- read_parquet(spp_filter$f) %>%
    mutate(aphiaid = id) %>% 
    dplyr::select(x, y, Current, all_of(s), cutoff)
  
  # Filter the df of entry into for this species & scenario
  exit_spp_df <- eez_spp_exit %>% 
    filter(aphiaid == id) %>% 
    filter(scenario == s)
  
  # Get the EEZs for which the species & scenario is entry
  spp_exit_eezs <- unique(exit_spp_df$GEONAME)
  
  # Join the eez dataframe and filter for the spp_entry_eezs
  spp_eez <- inner_join(spp, eez_raster_df) %>% 
    filter(GEONAME %in% spp_exit_eezs) %>% 
    filter(Current >= cutoff) %>% 
    mutate(binary_loss = 1) %>% 
    bind_rows()
  
  return(spp_eez)
}