# IDI definitions library
Duplicate copies of definitions from the Social Wellbeing Agency projects in a single repository for ease of discovery. These definitions are intended to be compatible with the Dataset Assembly Tool.

## Overview
The Dataset Assembly Tool encourages research projects to structure their input data into population and measures. The population is specific to a specific study and includes who is being studied and over what time period. The measures are not specific to a study. This means they can be reused across research projects.

When creating a new measure, researchers are encouraged to construct the best definition of the measure that they can. By creating and sharing high quality definitions, the quality of research will improve.

## Dependencies
Because these definitions are based on data in the IDI, it is necessary to have an IDI project if you wish to run the code. Visit the Stats NZ website for more information about this.

The definitions in this library were developed using specific versions/refreshes of the IDI. As the IDI is further developed, new refreshes will be released. When reusing these definitions, it is the researcher's responsibility to updated them if the refresh being used in the project does not match the original refresh of the definition. Trying to use different refreshes in the same project will likely result in errors and links between data sources can change between refreshes.

In addition to updating the refresh, researchers will need to update the project schema before running these definitions. Unless you have permission to create tables and views in the chosen schema, you will receive an error when you run a definition.

Any dependencies for an individual definition should be noted in the header at the top of the file.

## Folder descriptions
This repository contains duplicate copies of definitions from other projects. The folders in this project are named according to the project that the definitions originate from.

## Disclaimer
The definitions provided in this library were determined by the Social Wellbeing Agency to be suitable in the context of a specific project. Whether or not these definitions are suitable for other projects depends on the context of those projects. Researchers using definitions from this library will need to determine for themselves to what extent the definitions provided here are suitable for reuse in their projects. While the Agency provides this library as a resource to support IDI research, it provides no guarantee that these definitions are fit for reuse.

## Citation
Social Wellbeing Agency. Definitions library. Source code. https://github.com/nz-social-wellbeing-agency/definitions_library

## Getting Help
If you have any questions email info@swa.govt.nz
