### sample spp and get aphia ids for AquaX

library(tidyverse)
library(taxize)
spp_info <- read_csv('spp_chi_info.csv')

load('META_02122025.Rdata')

### All these species have data on traits, vulnerability, and distribution
### Species name is WoRMS accepted name as of running the process in 2022/2023ish

am_spp_available <- META %>%
  ungroup() %>%
  mutate(species = tolower(ScientificName)) %>%
  filter(taxonomicStatus == 'accepted') %>%
  filter(SDM == 'SDM') %>%
  inner_join(spp_info, by = 'species') %>%
  select(species, group = GROUP, taxon, AphiaID) %>%
  distinct()


set.seed(42)
verts <- c('marine_mammals', 'seabirds', 'reptiles', 'elasmobranchs', 'fish')
am_sample_inverts <- am_spp_available %>%
  filter(!taxon %in% verts) %>%
  slice_sample(n = 250)
am_sample_verts <- am_spp_available %>% 
  filter(taxon %in% verts & taxon != 'fish') %>%
  group_by(taxon) %>%
  slice_sample(n = 50) %>%
  ungroup()
am_sample_fish <- am_spp_available %>%
  filter(taxon == 'fish') %>%
  slice_sample(n = 200)

am_sample <- bind_rows(am_sample_inverts, am_sample_verts, am_sample_fish)

write_csv(am_sample, 'sample/sample_for_aquaX.csv')
