# Get species pixel counts by EEZ
extract_eez_zonal <- function(id, df, eez_raster) {
  spp_filter <- df %>% filter(aphiaid == id)
  
  if (nrow(spp_filter) == 0) {
    warning("No rows found for aphiaid: ", id)
    return(NULL)
  }
  
  spp <- read_parquet(spp_filter$f) %>%
    mutate(aphiaid = id)
  
  r_spp <- rast(spp, crs = "EPSG:4326") %>%
    extend(ext(eez_raster))
  
  cutoff <- mean(spp$cutoff, na.rm = TRUE)
  
  # Create binary layers: 1 if >= cutoff, NA otherwise
  # (zonal sum of 1s = count of cells above cutoff)
  r_binary <- ifel(r_spp[["Current"]]    >= cutoff, 1, NA)
  r_binary45_2050 <- ifel(r_spp[["RCP45_2050"]] >= cutoff, 1, NA)
  r_binary45_2100 <- ifel(r_spp[["RCP45_2100"]] >= cutoff, 1, NA)
  r_binary85_2050 <- ifel(r_spp[["RCP85_2050"]] >= cutoff, 1, NA)
  r_binary85_2100 <- ifel(r_spp[["RCP85_2100"]] >= cutoff, 1, NA)
  
  # Stack and name for clean output
  r_thresh <- c(r_binary, r_binary45_2050, r_binary45_2100,
                r_binary85_2050, r_binary85_2100)
  names(r_thresh) <- c("n_current", "n_RCP45_2050", "n_RCP45_2100",
                       "n_RCP85_2050", "n_RCP85_2100")
  
  # zonal() sums the binary layers within each EEZ zone
  result <- zonal(r_thresh, eez_raster, fun = "sum", na.rm = TRUE)
  
  # eez_raster zones are numeric IDs — join back to EEZ names
  result %>%
    #left_join(eez_zone_lookup, by = "GEONAME") %>%
    # add aphiaid to track each species
    mutate(aphiaid = id) %>% 
    filter(!if_all(c(n_current, n_RCP45_2050, n_RCP45_2100,
                     n_RCP85_2050, n_RCP85_2100), is.na))
}