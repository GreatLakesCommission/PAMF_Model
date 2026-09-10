# Phase-Date Decisions

This chart shows the decisions made in the script [**phase-date-agreement.R**](/src/construct-datpaks/phase-date-agreement.R). These decisions determine which management phase a management report falls into based on the report's quality, reported date(s), management action, and other information.  

```mermaid
flowchart LR
subgraph sgclass[Step 2. After phases are determined]
direction TB
    GG[Does reported phase disagree with<br>model phase for ALL applications?] --> |Yes| HH[Create rest report<br>in vacated phase]:::decision
    GG --> |No| II[Do nothing]:::decision
end
subgraph runapp[Step 1. Determine the phases]
direction TB
    A[Was the management report rejected?] -->|No| B[Is the management report from a<br>cycle other than this one?]
    A -->|Yes| C[Ignore it]:::decision
    B --> |Yes| C[Ignore it]:::decision
    B --> |No| D
    D[Is the action REST?] -->|No| E[Is the action FLOOD?]
    D --> |Yes| F[Use reported phase]:::decision
    E --> |Yes| F[Use reported phase]:::decision
    E --> |No| G[Is the application date in <br>Translocating only and NOT August?]
    G --> |Yes| H[Use Translocating phase]:::decision
    G --> |No| I[Is the application date in<br>Translocating / Dormant overlap?]
    I --> |Yes| J[Is the reported phase<br>Translocating or Dormant?]
    J --> |Yes| K[Use reported phase]:::decision
    J --> |No| L[Unresolved phase]:::decision
    I --> |No| M[Is the application date<br>in Dormant only?]
    M --> |Yes| N[Use Dormant phase]:::decision
    M --> |No| O[Is the application date<br>in Dormant / Growing overlap?]
    O --> |Yes| P[Is the reported phase<br>Dormant or Growing?]
    P --> |Yes| Q[Use reported phase]:::decision
    P --> |No| R[Unresolved phase]:::decision
    O --> |No| T[Is there a monitoring report<br>in the same year as the<br>application date?]
    T --> |Yes| U[Is the application date<br>in Growing only?]
    U --> |Yes| V[Is the application date<br>after the monitoring date?]
    U --> |No| W[Is the application date<br>in August?]
    V --> |Yes| X[Use Growing phase]:::decision
    V --> |No| Y[Use Translocating phase]:::decision
    W --> |Yes| Z[Use Translocating phase]:::decision
    W --> |No| AA[Use Growing phase]:::decision
    T --> |No| BB[Is the application date<br>in Growing only?]
    BB --> |Yes| DD[Use Growing phase]:::decision
    BB --> |No| CC[Was the application<br>done in August?]
    CC --> |Yes| EE[Use Translocating phase]:::decision
    CC --> |No| FF[NOT POSSIBLE]:::decision
end

style runapp fill:#FFFFFF,stroke:#FFFFFF,stroke-width:2px
style sgclass fill:#FFFFFF,stroke:#FFFFFF,stroke-width:2px
classDef decision fill:#a0e0e8;
```