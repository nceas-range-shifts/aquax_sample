Full method descriptions can be found in: 

Reygondeau, G., Egorova, Y., Boerder, K., Tittensor, P.D.,  Kaschner, K.,  Kesner-Reyes, K., Bailly, N., Cheung, W.W.L (2025).  AquaX: An enhanced and revised AquaMaps framework to model marine species distributions and biodiversity. PLOS One (accepted). Pre-print available: https://doi.org/10.1101/2025.10.19.683322

#########################
META File Description
#########################

This dataset, META, contains species-level taxonomic, ecological, and occurrence information for marine organisms. 
The dataset integrates taxonomic classifications, habitat preferences, depth ranges, conservation status, and occurrence records.
The last 11 columns belong to the D3OS system, categorizing species based on their habitat and ecological traits.

Column Descriptions

Taxonomic Information
	•	AphiaID (num): Unique identifier from the World Register of Marine Species (WoRMS).
	•	ScientificName (chr): Full scientific name of the species.
	•	kingdom (chr): Kingdom classification (e.g., Animalia).
	•	phylum (chr): Phylum classification (e.g., Chordata).
	•	class (chr): Class classification (e.g., Teleostei).
	•	order (chr): Order classification (e.g., Mulliformes).
	•	family (chr): Family classification (e.g., Mullidae).
	•	genus (chr): Genus classification (e.g., Parupeneus).
	•	species (chr): Species name (e.g., pleurostigma).
	•	taxonRank (chr): Taxonomic rank of the entry (e.g., Species).
	•	scientificNameAuthorship (chr): Authorship and year of species description.
	•	taxonomicStatus (chr): Status of the species (e.g., accepted).

Habitat and Environmental Information
	•	isMarine (num): Indicates if the species is marine (1 = Yes, 0 = No).
	•	isFreshwater (num): Indicates if the species is freshwater (1 = Yes, 0 = No).
	•	isTerrestrial (num): Indicates if the species is terrestrial (1 = Yes, 0 = No).
	•	isExtinct (num): Indicates if the species is extinct (1 = Yes, 0 = No).
	•	isBrackish (num): Indicates if the species is found in brackish waters (1 = Yes, 0 = No).
	•	HAB (chr): Habitat type (e.g., reef-associated, pelagic-neritic).
	•	DepthRangeShallow (num): Minimum depth range (meters).
	•	DepthRangeDeep (num): Maximum depth range (meters).

Conservation and Occurrence Data
	•	IUCN_map (num): IUCN status (0 = Not assessed, 1 = Assessed).
	•	SPID (int): Unique species ID within the dataset.
	•	OCC (int): Number of recorded occurrences for the species.
	•	GOODOCC (num): Number of occurrences withing biogeographical range (BR, see below).
	•	NR_CR (num): Number of range and confidence regions.
	•	range_pixels (num): Species range area in pixel units.

D3OS System (AquaX Ecological Categorization)
    Distance to Bottom:
	•	Pelagic (num): Indicates if the species is pelagic (1 = Yes, 0 = No).
	•	Demersal (num): Indicates if the species is demersal (1 = Yes, 0 = No).
	•	Benthic (num): Indicates if the species is benthic (1 = Yes, 0 = No).
	  Distance to Coast:
	•	Neritic (num): Presence in neritic zones (1 = Yes, NA = Not classified).
	•	Oceanic (num): Presence in oceanic zones (1 = Yes, NA = Not classified).
	Distance to Surface:
	•	Coastal (num): (for Benthic/Demersal species) Presence in coastal areas (1 = Yes, NA = Not classified).
	•	Bathyal (num): (for Benthic/Demersal species) Presence in bathyal zones (1 = Yes, NA = Not classified).
	•	Abyssal_Hadal (num): (for Benthic/Demersal species) Presence in abyssal or hadal zones (1 = Yes, NA = Not classified).
	•	Epipelagic (num): (for Pelagic species) Presence in the epipelagic zone (1 = Yes, NA = Not classified).
	•	Mesopelagic (num): (for Pelagic species) Presence in the mesopelagic zone (1 = Yes, NA = Not classified).
	•	Bathypelagic (num): (for Pelagic species) Presence in the bathypelagic zone (1 = Yes, NA = Not classified).
	
	
#########################
OCC folder
#########################

The Occurrence folder contains species occurrence data, with each file corresponding to a specific species based on its AphiaID from the META file. Each file follows the naming convention:

occurence_SP_<AphiaID>.Rdata

Where <AphiaID> is a unique numerical identifier from WoRMS (World Register of Marine Species).

File Structure

Each file is an R data file (.Rdata) containing a data frame `DATA` with species occurrence records. The structure of these files is as follows:

Columns Description
	•	APHIAID (int): Unique taxonomic identifier for the species.
	•	latitude (num): Latitude coordinate of the occurrence record.
	•	longitude (num): Longitude coordinate of the occurrence record.
	•	yearcollected (num): Year the occurrence was recorded (may contain missing values).
	•	monthcollected (num): Month the occurrence was recorded (may contain missing values).
	•	DATABASE (chr): Source of the occurrence data (e.g., GBIF, OBIS).
	•	GOODOCC (num): Flag indicating high-confidence occurrence records (1 = Good, 0 = Low quality, NA = Unknown).
	•	basisOfRecord (chr): Type of data collection method (e.g., human observation, specimen, literature).
	
#########################
RANGEMAP folder
#########################
The RANGEMAP folder contains species range maps, with each file corresponding to a specific species based on its AphiaID from the META file. Each file follows the naming convention:

RANGEMAP_SP_<AphiaID>.Rdata

Where <AphiaID> is a unique numerical identifier from WoRMS (World Register of Marine Species).

File Structure

Each file contains two spatial objects:

NR (Biogeographical Range)-The area where a species is currently known to exist, generated by applying a 1° buffer around the “expert range map”.
	•	A simple feature collection (sf object) with one feature representing the native range (NR) of the species.
	•	Stored as a MULTIPOLYGON, indicating the geographical extent where the species is naturally found.
	•	The bounding box (xmin, ymin, xmax, ymax) provides the spatial extent of the species’ distribution.
	•	The dataset is based on the WGS 84 geodetic coordinate reference system (CRS).

CR (Potential Range)-The area where a species could potentially exist, created by applying a 9° buffer to BR.
	•	A simple feature collection (sf object) with one feature representing the conservative range (CR) of the species.
	•	Stored as a MULTIPOLYGON, indicating a more conservative estimate of the species’ distribution, possibly accounting for habitat suitability constraints.
	•	The bounding box provides the spatial extent for the conservative range.
	•	The dataset is based on the WGS 84 geodetic CRS.
	
#########################
SDM folder
#########################

The SDM folder contains species distribution model (SDM) outputs, with each file corresponding to a specific species based on its AphiaID from the META file. Each file follows the naming convention:

FINAL_EMSDM_EMMEAN_SP_<AphiaID>.Rdata

Where <AphiaID> is a unique numerical identifier from WoRMS (World Register of Marine Species).

File Structure

Each file contains a data frame (FINALEMMEAN) with species distribution predictions under current and future climate scenarios for AquaX mean ensemble.

Columns Description
	•	x (num): Longitude coordinate.
	•	y (num): Latitude coordinate.
        •	Current_NR (num): Predicted habitat suitability index under present-day conditions cropped by biogeographic range of the species (see explanations in RANGEMAP folder for biogeographical range). Scale 0-1000. If you need current distribution of the species, please use this column.
	•	Current (num): Predicted habitat suitability index under present-day conditions. Scale 0-1000. Please use this column of you want to calculate the difference between Future and current scenarios.
	•	RCP26_2050 (num): Predicted habitat suitability under SSP1-2.6 (low emissions scenario) for the year 2050.Scale 0-1000.
	•	RCP26_2100 (num): Predicted habitat suitability under SSP1-2.6 for the year 2100.Scale 0-1000.
	•	RCP45_2050 (num): Predicted habitat suitability under SSP2-4.5 (moderate emissions scenario) for the year 2050.Scale 0-1000.
	•	RCP45_2100 (num): Predicted habitat suitability under SSP2-4.5 for the year 2100.Scale 0-1000.
	•	RCP85_2050 (num): Predicted habitat suitability under SSP5-8.5 (high emissions scenario) for the year 2050.Scale 0-1000.
	•	RCP85_2100 (num): Predicted habitat suitability under SSP5-8.5 for the year 2100.Scale 0-1000.
	•	cutoff (num): TSS-based threshold value for presence-absence classification.
	•	AUC (num): Area Under the Curve (AUC) score for model performance evaluation (higher values indicate better predictive accuracy).
	•	TSS (num): True Skill Statistic (TSS) score, another metric for model accuracy.
