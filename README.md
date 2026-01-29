
# The-Torque-Awakens

A custom Godot 4.x 2D structural analysis tool. It features a Truss Solver for nodal frameworks and a Statics Environment for calculating equilibrium between walls, boxes, and circles.




## Features

This project can solve Truss related problems and display the values of force in each member and also display its type(Tension/Compression).

Additionally, It is also able to solve basic Statics Problems.
## Tech Stack


+ Engine: Godot 4.x

+ Scripting: GDScript

+ Math Logic: Custom Matrix Solvers (no external libraries)

+ Rendering: Draw Calls / Sprites
## Installation


1. Clone the Repository:

```bash
git clone https://github.com/MDGSpace-SOC-D-2025/The-Torque-Awakens
```



2.  Import into Godot:

3. Open the Godot Engine 4.x Project Manager.

4. Click the Import button.

5. Navigate to the cloned folder and select the project.godot file.

6. Click Import & Edit to load the project into the editor.

7. Press F5 or the Play button in the top right corner to start from main_menu.tscn.
## Usage

###  Truss

+ M: Truss Drawing Mode
+ F: Force Drawing Mode
+ S: Support
+ Left-Click: Generate object in specific Mode
+ Right-Clicl: Remove object in specific Mode
+ Enter: Solve
+ Space: Clear Screen

###  Statics

+ W: Wall Drawing Mode
+ B: Box Drawing Mode
+ C: Circle Drawing Mode
+ F: Force Drawing Mode
+ Left-Click: Generate object in specific Mode
+ Right-Click: Remove object in specific Mode
+ Enter: Solve
+ Space: Clear Screen

## Project Structure

```
res://
├── assets/                     
│   ├── HingeJoint.png          
│   ├── JosefinSans-Bold.ttf
│   ├── RollerJoint.png         
│   ├── Screen.svg              
│   ├── SIL Open Font License.txt
│   └── TrussConfig.tres        
├── scenes/                     
│   ├── gd_statics.tscn         
│   ├── main_menu.tscn          
│   └── trussdraw.tscn          
├── scripts/
│   ├── statics/                
│   │   ├── gd_statics.gd       
│   │   ├── gd_statics_camera.gd
│   │   ├── statics_solver.gd   
│   │   ├── staticscontact_data.gd
│   │   ├── staticscontact_detector.gd
│   │   ├── staticsdataclasses.gd
│   │   ├── staticsforce_data.gd
│   │   ├── staticsforce_manager.gd
│   │   ├── staticsobject_manager.gd
│   │   ├── staticsrenderer.gd  
│   │   ├── staticsrigid_objects.gd 
│   │   └── staticswall_manager.gd
│   └── truss/                  
│       ├── camera_2d.gd
│       ├── renderer.gd         
│       ├── TrussConfig.gd
│       ├── trussdraw.gd        
│       ├── TrussInputManager.gd
│       ├── TrussMath.gd        
│       ├── TrussMember.gd      
│       └── TrussSolver.gd      
├── main_menu.gd                
├── icon.svg
└── project.godot
```
## Roadmap

+ Truss Drawing tools
+ Truss Supports
+ Truss Loads
+ Force Generator
+ Truss Solver
+ Statics Shape tools
+ Statics Solver

## Known Issues

+ Statics Solver might sometimes solve for edge-cases(slightly unstable).

+ Truss Solver has no dialog box for forces.
