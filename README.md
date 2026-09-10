# *Phragmites* Adaptive Management Framework (PAMF) Model    

The PAMF Model is the foundation of the 
[*Phragmites* Adaptive Management Framework](https://www.greatlakesphragmites.net/pamf/). 
PAMF is an adaptive management and collective learning program that anyone 
managing *Phragmites* can join. Participants from around the Great Lakes basin 
submit *Phragmites* monitoring and management data to bolster the PAMF predictive 
model, which uses participant data to continually 'learn' more about which 
management techniques are working to reduce *Phragmites* infestations and which 
ones are not. In turn, the PAMF model predicts optimal management guidance for 
each site being managed based on the most up-to-date information collected from 
all the participants. This process repeats annually, reducing management 
uncertainty with additional data collected. By undergoing this collective 
learning process, PAMF can determine which management techniques are efficient 
and effective for controlling *Phragmites* quicker than if participants were 
working alone. The goal of PAMF is to determine best management practices 
for *Phragmites* in the Great Lakes. 

<img src="/user-guide/images/Model_graphic.png" width="700"/>  

Figure 1. Conceptual diagram of the PAMF Model. The PAMF Model's underlying 
state and transition model is updated yearly with monitoring and management data 
provided by program participants. The Model produces management guidance in the 
form of management combinations that are effective at reducing *Phragmites* invasion 
and are optimized by cost, satisfaction, and usage of past guidance.   

## Disclaimer  

This code is maintained by the Great Lakes Commission, but is built upon work 
previously released by the U.S. Geological Survey. This repository is considered 
the newest version of the code. The previous USGS version of the code can be found 
here: https://doi.org/10.5066/P14AGFZ9  

## Requirements

The PAMF Model was developed in [R version 4.1.0 (2021)](https://cran.r-project.org/) 
using the following packages:  

- [shiny 1.7.4](https://cran.r-project.org/web/packages/shiny/index.html)
- [rmarkdown 2.20](https://cran.r-project.org/web/packages/rmarkdown/index.html)
- [MDPToolbox 4.0.3](https://cran.r-project.org/web/packages/MDPtoolbox/index.html)

Note that additional packages are occasionally sourced in standalone code files 
found in this repository, but are not needed to run the PAMF Model. These packages 
are indicated at the top of standalone R scripts.  

**Hardware requirements:** A computer able to run R / R Studio.  
**Runtime:** Running the code itself typically takes 1–2 minutes and is not 
computationally intense. However, the process requires manual data verification 
partway through, which can significantly extend the overall time. Depending on 
the size of the dataset, this manual review may take several hours.  

## Authors         

- Christine E. Dumoulin - U.S. Geological Survey; [https://orcid.org/0000-0001-7587-9417](https://orcid.org/0000-0001-7587-9417)  
- Taaja R. Tucker-Silva - Great Lakes Commission; taaja@glc.org; [https://orcid.org/0000-0003-1534-4677)](https://orcid.org/0000-0003-1534-4677)  
- Emily E. Jameson - Work done under contract to U.S. Geological Survey; [https://orcid.org/0000-0003-0882-2116](https://orcid.org/0000-0003-0882-2116)  

## Point of Contact  

- Taaja R. Tucker-Silva - Great Lakes Commission; taaja@glc.org  
- Christine E. Dumoulin - U.S. Geological Survey

## Suggested citation  

Dumoulin, C. E., T. R. Tucker-Silva, and E. E. Jameson. 2026. *Phragmites* Adaptive 
Management Framework Model v.2.0.0. https://github.com/GreatLakesCommission/PAMF_Model 

## Acknowledgements  

- US Geological Survey - Original code and expertise
- University of Georgia - PAMF Web Hub Administration
- Great Lakes Restoration Initiative - Funding   

## Getting Started  

- View the PAMF Model [User Guide](user-guide/user-guide.md) to set up data files and run the PAMF Model.  
- View the PAMF Model [Overview](user-guide/model-overview.md) to understand the model's structure and components.  

