library(tidyverse)
load('data/META_02122025.Rdata')

x <- META %>%
  janitor::clean_names() %>%
  filter(iucn_map == 1) %>%
  select(group, scientific_name, aphia_id) %>%
  distinct()
write_csv(x, 'tmp/iucn_request.csv')
