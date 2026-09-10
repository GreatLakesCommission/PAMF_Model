# USER-GUIDE

Explanations and schematics to help a user run the PAMF Model. 

## DIRECTORIES  

- :file_folder: [images](/user-guide/images/)  
Folder containing images used in the user guide markdown files.  

## FILES 

- [Table_metadata.csv](/user-guide/Table_metadata.csv)  
CSV file containing metadata for each column in each CSV file found in the PAMF Model.  
Description of each column in this CSV:  

  - TABLE_NAME  
    Name of CSV file.  
  - TABLE_LOCATION  
    Path to the CSV file folder.  
  - TABLE_NOTES  
    Notes about the data the table contains.  
  - DATA_ELEMENT_NAME  
    Column name.  
  - DATA_ELEMENT_ORDER  
    Order of column (represented by "DATA_ELEMENT_NAME") in the CSV.  
  - DATA_ELEMENT_DESCRIPTION  
    Description of the data in the column represented by "DATA_ELEMENT_NAME".  
  - DATA_TYPE  
    Type of data contained in the column represented by "DATA_ELEMENT_NAME" (e.g., numeric, character, etc.).  


- [base-runs.md](/user-guide/base-runs.md)  
File explaining what base PAMF Model runs are and how to create them.  

- [model-overview.md](/user-guide/model-overview.md)  
Overview of the PAMF Model.  

- [model-schematic.md](/user-guide/model-schematic.md)  
Schematic of how all the PAMF Model's scripts interact with eachother.  

- [phase-date-decisions.md](/user-guide/phase-date-decisions.md)  
The Phase-date decisions schematic shows how the decisions are made in ["**phase-date-agreement.R**"](src/construct-datpaks/phase-date-agreement.R). These decisions determine which management phase a management report falls into based on the report's quality, reported date(s), management action, and other information.  

- [user-guide.md](/user-guide/user-guide.md)  
The user guide for running the PAMF Model.  

