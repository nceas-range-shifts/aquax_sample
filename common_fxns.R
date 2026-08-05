# Get species pixel counts by EEZ
extract_eez_zonal <- function(id, df, eez_raster) {
  spp_filter <- df %>% filter(aphiaid == id)
  
  if (nrow(spp_filter) == 0) {
    warning("No rows found for aphiaid: ", id)
    return(NULL)
  }
  
  spp <- read_parquet(spp_filter$f) %>%
    mutate(aphiaid = id) %>% 
    # round xy data
    mutate(x = round(x, 3),
           y = round(y, 3))
  
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

# Get species pixel counts by EEZ using duckdb to filter first
extract_eez_zonal_db <- function(id, df, eez_raster, s) {
  spp_filter <- df %>% filter(aphiaid == id)
  
  if (nrow(spp_filter) == 0) {
    warning("No rows found for aphiaid: ", id)
    return(NULL)
  }
  
  # Create database connection
  con <- DBI::dbConnect(duckdb::duckdb())
  
  query_str <- paste0("SELECT ROUND(x, 3) AS x, ROUND(y, 3) AS y, ", paste(s, collapse = ", "), 
                      " FROM read_parquet('", spp_filter$f, "')",
                      " WHERE ", paste(s, collapse = ", "), " >= cutoff")
  
  # Run query and filter for scenario pixels above cutoff threshold
  
  spp_df <- DBI::dbGetQuery(con, query_str) 
  
  # Close connection
  duckdb::dbDisconnect(con, shutdown = TRUE)
  
  # Set option for if there are no pixels above the cutoff threshold
  if (nrow(spp_df) == 0) {
    warning("No pixels above cutoff threshold for aphiaid: ", id)
    # Still need to shut connection in this case
    duckdb::dbDisconnect(con, shutdown = TRUE)
    # Return NA to track loss species
    return(data.frame(MRGID = NA, n_pixel = NA, aphiaid = id, scenario = s))
  } else {
    # Create raster
    r_spp <- rast(spp_df, crs = "EPSG:4326") %>% 
      extend(ext(eez_raster))
    
    # zonal() counts the notNA pixels within each EEZ zone (don't need binary)
    result <- zonal(r_spp, eez_raster, fun = "notNA", na.rm = TRUE)
    
    # eez_raster zones are numeric IDs — join back to EEZ names
    result %>%
      #left_join(eez_zone_lookup, by = "GEONAME") %>%
      # add aphiaid to track each species
      mutate(aphiaid = id,
             scenario = s) %>% 
      rename(n_pixel = .data[[s]]) %>% 
      # Drop rows where there are 0  notNA pixels
      filter(n_pixel != 0)}
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

# Get entry pixels using duckdb to filter first
extract_eez_entry_pixels_df_db <- function(id, df, s, eez_spp_entry, eez_raster_df) {
    spp_filter <- df %>% filter(aphiaid == id)
  
    if (nrow(spp_filter) == 0) {
      warning("No rows found for aphiaid: ", id)
      return(NULL)
  }

  # Create database connection
  con <- DBI::dbConnect(duckdb::duckdb())
  # Ensure connection is closed 
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  # Write query to round x and y to 3 decimal places and filter for scenario pixels at or above cutoff threshold
   query_str <- paste0("SELECT ROUND(x, 3) AS x, ROUND(y, 3) AS y, ", paste(s, collapse = ", "), 
                      " FROM read_parquet('", spp_filter$f, "')",
                      " WHERE ", paste(s, collapse = ", "), " >= cutoff")

 # Run query and filter for scenario pixels above cutoff threshold
    spp <- DBI::dbGetQuery(con, query_str) 

  # Set option for if there are no pixels above the cutoff threshold
    if (nrow(spp) == 0) {
        warning("No pixels above cutoff threshold for aphiaid: ", id)
        # Return NA to track no pixels above threshold
      return(data.frame(x = NA, y = NA, MRGID = NA, binary = 0))
    } else {
  
  # Filter the df of EEZ species entry into for this species & scenario
    entry_spp_df <- eez_spp_entry %>% 
      filter(aphiaid == id) %>% 
      filter(scenario == s)
  
  # Get the EEZs for which the species & scenario is entry
    spp_entry_eezs <- unique(entry_spp_df$MRGID)
  
  # Join the eez dataframe and filter for the spp_entry_eezs
    spp_eez <- inner_join(spp, eez_raster_df, by = c("x", "y")) %>% 
      filter(MRGID %in% spp_entry_eezs) %>% 
      mutate(binary = 1) %>%  
      dplyr::select(x, y, MRGID, binary)
  
  return(spp_eez)
  }
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
  
  # Filter the df of exits into for this species & scenario
  exit_spp_df <- eez_spp_exit %>% 
    filter(aphiaid == id) %>% 
    filter(scenario == s)
  
  # Get the EEZs for which the species & scenario is exit
  spp_exit_eezs <- unique(exit_spp_df$GEONAME)
  
  # Join the eez dataframe and filter for the spp_exit_eezs
  spp_eez <- inner_join(spp, eez_raster_df) %>% 
    filter(GEONAME %in% spp_exit_eezs) %>% 
    filter(Current >= cutoff) %>% 
    mutate(binary_loss = 1) %>% 
    bind_rows()
  
  return(spp_eez)
}

# Get continued presence pixels for a species by EEZ
extract_eez_cp_pixels_df <- function(id, df, s, eez_spp_cp, eez_raster_df) {
  spp_filter <- df %>% filter(aphiaid == id)
  
  if (nrow(spp_filter) == 0) {
    warning("No rows found for aphiaid: ", id)
    return(NULL)
  }
  
  spp <- read_parquet(spp_filter$f) %>%
    mutate(aphiaid = id) %>% 
    dplyr::select(x, y, Current, all_of(s), cutoff)
  
  # Filter the df of entry into for this species & scenario
  cp_spp_df <- eez_spp_cp %>% 
    filter(aphiaid == id) %>% 
    filter(scenario == s)
  
  # Get the EEZs for which the species & scenario is continued presence
  spp_cp_eezs <- unique(cp_spp_df$GEONAME)
  
  # Join the eez dataframe and filter for the spp_entry_eezs
  spp_eez <- inner_join(spp, eez_raster_df) %>% 
    filter(GEONAME %in% spp_cp_eezs) %>% 
    filter(Current >= cutoff) %>% 
    mutate(binary_loss = 1) %>% 
    bind_rows()
  
  return(spp_eez)
}

# Get exit pixels using duckdb to filter first
extract_eez_exit_pixels_df_db <- function(id, df, s, eez_spp_exit, eez_raster_df) {
    spp_filter <- df %>% filter(aphiaid == id)
  
    if (nrow(spp_filter) == 0) {
      warning("No rows found for aphiaid: ", id)
      return(NULL)
  }

  # Create database connection
  con <- DBI::dbConnect(duckdb::duckdb())
  # Ensure connection is closed 
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  # Write query to round x and y to 3 decimal places and filter for scenario pixels at or above cutoff threshold
   query_str <- paste0("SELECT ROUND(x, 3) AS x, ROUND(y, 3) AS y, Current", 
                      " FROM read_parquet('", spp_filter$f, "')",
                      " WHERE Current >= cutoff")

 # Run query and filter for scenario pixels above cutoff threshold
    spp <- DBI::dbGetQuery(con, query_str) 

  # Set option for if there are no pixels above the cutoff threshold
    if (nrow(spp) == 0) {
        warning("No pixels above cutoff threshold for aphiaid: ", id)
        # Return NA to track no pixels above threshold
      return(data.frame(x = NA, y = NA, MRGID = NA, binary = 0))
    } else {
  
  # Filter the df of EEZ species exit into for this species & scenario
    exit_spp_df <- eez_spp_exit %>% 
      filter(aphiaid == id) %>% 
      filter(scenario == s)
  
  # Get the EEZs for which the species & scenario is exit
    spp_exit_eezs <- unique(exit_spp_df$MRGID)
  
  # Join the eez dataframe and filter for the spp_entry_eezs
    spp_eez <- inner_join(spp, eez_raster_df, by = c("x", "y")) %>% 
      filter(MRGID %in% spp_exit_eezs) %>% 
      mutate(binary = 1) %>%  
      dplyr::select(x, y, MRGID, binary)
  
  return(spp_eez)
  }
}

# Calculate area function
calculate_area <- function(id, df, scenario, unit) {
    spp_filter <- df %>% filter(aphiaid == id)
  
  if (nrow(spp_filter) == 0) {
    warning("No rows found for aphiaid: ", id)
    return(NULL)
  }

  # Create database connection
  con <- DBI::dbConnect(duckdb::duckdb())

  query_str <- paste0("SELECT x, y, cutoff, ", paste(scenario, collapse = ", "), 
    " FROM read_parquet('", spp_filter$f, "')",
    " WHERE ", paste(scenario, collapse = ", "), " >= cutoff")

 # Run query and filter for scenario pixels above cutoff threshold

    spp_df <- DBI::dbGetQuery(con, query_str) 

  # Close connection
  duckdb::dbDisconnect(con, shutdown = TRUE)

  # Set option for if there are no pixels above the cutoff threshold
    if (nrow(spp_df) == 0) {
        warning("No pixels above cutoff threshold for aphiaid: ", id)
        # Still need to shut connection in this case
        duckdb::dbDisconnect(con, shutdown = TRUE)
        # Return 0 to track loss species
        return(data.frame(aphiaid = id, area = 0, s = scenario))
    }
  
  # Create raster
  r_spp <- rast(spp_df, crs = "EPSG:4326") 

  # Calculate area of scenario pixels
  r_spp_df <- r_spp[[scenario]] %>%
    terra::expanse(unit = unit) %>% 
    #as.data.frame() %>% 
    mutate(aphiaid = id,
    s = scenario)
  
  return(r_spp_df)
}

least_concern_count_xmin_xmax <- function(id, df, scenario, xmin, xmax, n_threads = 1) {
    spp_filter <- df %>% filter(aphiaid == id)
  
  if (nrow(spp_filter) == 0) {
    warning("No rows found for aphiaid: ", id)
    return(NULL)
  }

  # Create database connection
  con <- DBI::dbConnect(duckdb::duckdb())

  # Ensure connection is closed 
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  # Cap threads so that function doesn't overscribe and hang
  DBI::dbExecute(con, paste0("PRAGMA threads = ", n_threads, ";"))

  query_str <- paste0("SELECT ROUND(x, 3) AS x, ROUND(y, 3) AS y, ", paste(scenario, collapse = ", "), 
    " FROM read_parquet('", spp_filter$f, "')",
    " WHERE ", paste(paste(scenario, ">= cutoff"), collapse = " AND "),
    " AND x >= ", xmin, " AND x < ", xmax)

 # Run query and filter for scenario pixels above cutoff threshold

    spp_df <- DBI::dbGetQuery(con, query_str) 

  # Set option for if there are no pixels above the cutoff threshold
    if (nrow(spp_df) == 0) {
        warning("No pixels above cutoff threshold for aphiaid: ", id)
      # Return 0 to track loss species
        return(data.frame(x = NA, y = NA, binary = 0, s = scenario))
    } else {
  
  # Return the pixels above the cutoff to be summarized into LC count  
  spp_df_clean <- spp_df %>% 
    mutate(binary = 1) %>%  
    dplyr::select(x, y, binary) %>% 
    mutate(s = scenario)

  return(spp_df_clean)
}}

least_concern_count <- function(id, df, scenario, n_threads = 1) {
    spp_filter <- df %>% filter(aphiaid == id)
  
  if (nrow(spp_filter) == 0) {
    warning("No rows found for aphiaid: ", id)
    return(NULL)
  }

  # Create database connection
  con <- DBI::dbConnect(duckdb::duckdb())

  # Ensure connection is closed 
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  # Cap threads so that function doesn't overscribe and hang
  DBI::dbExecute(con, paste0("PRAGMA threads = ", n_threads, ";"))

  query_str <- paste0("SELECT ROUND(x, 3) AS x, ROUND(y, 3) AS y, ", paste(scenario, collapse = ", "), 
    " FROM read_parquet('", spp_filter$f, "')",
    " WHERE ", paste(scenario, collapse = ", "), " >= cutoff")

 # Run query and filter for scenario pixels above cutoff threshold

    spp_df <- DBI::dbGetQuery(con, query_str) 

  # Set option for if there are no pixels above the cutoff threshold
    if (nrow(spp_df) == 0) {
        warning("No pixels above cutoff threshold for aphiaid: ", id)
      # Return 0 to track loss species
        return(data.frame(x = NA, y = NA, binary = 0, s = scenario))
    } else {
  
  # Return the pixels above the cutoff to be summarized into LC count  
  spp_df_clean <- spp_df %>% 
    mutate(binary = 1) %>%  
    dplyr::select(x, y, binary) %>% 
    mutate(s = scenario)

  return(spp_df_clean)
}}