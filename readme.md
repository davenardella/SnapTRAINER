# SnapTRAINER

![](img/Gallery_small.png)

When we create control software with a PLC we need to test it.

Suppose we have written the control software for one of our stations which is part of an automatic production line and which, among other things, contains some pneumatic cylinders; the program convinces us but now we have to try it (Later you will see what a pneumatic cylinder is and how it works).

We almost certainly don't physically have the station, so we decide to organize ourselves with the typical peripherals present in traditional trainer kits, i.e. switches and buttons connected to the I/O of the PLC.

Well, to simulate a single cylinder we need two inputs and two outputs.

How do we organize ourselves for the cycle? Simple, when we observe the LED that simulates the extension valve turning on, we wait a few seconds and then activate the switch that simulates the extended cylinder sensor and vice versa.

Ok, but what do we do for six or eight cylinders? Which constitute little stuff for a real station.

And what if we also need to manage start/stop buttons and lamps?

Assuming we have sufficient I/O, we will be completely focused on controlling the LEDs and operating the various switches, leaving out the most important part: our program.

**In practice we find ourselves unable to manage the testing of an automation that is even too banal.**

---

**SnapTRAINER** is a modular Virtual PLC-Trainer that allows us to free ourselves from these problems; it allows us to simulate external hardware through the use of specific intelligent modules.

It is a **64-bit** application for Windows (W7/W10/W11).

The name follows a bit of a tradition of mine; first I wrote **Snap7**, a cross-platform library for communication with Siemens PLCs, later I produced **SnapMODBUS**, also cross-platform to handle Modbus communication, so it seemed appropriate to call the simulator SnapTRAINER.

On github you can find the manual organized by modules, suitable for expansion. I give here a summary explanation and philosophy of operation. 

SnapTRAINER consists of a virtual switchboard containing 24 slots divided over 8 DIN rails, in each slot a virtual module selected from a list can be housed.

The list is compiled at the start based on the libraries present (each module is a DLL); in the future, once other DLLs for new modules are created, they will automatically be included in the list. 

![](img/snaptrainer_empty.png)

Each module simulates a component or group of components and communicates with the PLC by reading and writing registers.

![](img/module_menu.png)

Once a module is inserted into a slot, opening its context menu will show four options.
* **Remove** Module to delete the module. 
* **Change Module caption** to change the instance name (in the figure "MAIN TANK"). 
* **Exchange with slot Number... to** exchange the module with the one in the selected slot (or simply to move it if the destination slot is empty). 
* **Settings** which will open the instance parameter editing window. 

I better specify the concept of instance.
When we insert a new module, we are going to create a room of the selected family; we can insert multiple modules of the same family, for example, eight digital I/O modules; each one will behave the same way, but will have its own parameters distinct from those of the other modules.

The set of modules with their parameters, their arrangement on the control cabinet and the general communication parameters constitutes a **SnapTRAINER Project**, which can be saved and reloaded in the future via the main menu.

Such a project is a **single file**; an appropriate place to store it is in the project folder of the PLC referred to.

![](img/main_menu.png)

Still with the main menu we can create a new project or save the current one under another name and/or in another folder, as well as activate the communication parameterization window.

Finally, the **Play** button starts the simulation and thus physical communication with the PLC, and the Pin button, the blue one in the upper right, allows you to keep the application in the foreground at all times, which is very convenient if you have only one PC with which you do both programming and simulation.

 
## Communication

Each module, in order to work, needs to exchange bits or values with the PLC, these are organized in **16-bit Registers** that are **completely generic**, in fact, the modules do not know the PLC or the communication modes, they read and write in an internal SnapTRAINER area; the internal multiprotocol communication processor will take care of transferring data to and from the PLC.

Communication with the PLC therefore is not simulated, but **real**. Two protocols are available: Modbus (managed by SnapMODBUS libraries) and S7 (managed by Snap7).

By selecting Modbus, you can choose between Modbus/TCP (Ethernet-based) or Modbus/RTU (via RS485 or RS232). In either case, SnapTRAINER can be configured as either **Master** or **Slave**. 

![](img/communication_table.png)

To select the type of communication, you will actually often want to start in the right-hand column; that is, determine what protocol and mode are supported by your PLC and select the SnapTRAINER mode accordingly.

Let us now look at the various communication patterns, but first some important notes:

* When we talk about Modbus the discussion is to be understood indifferently for TCP and RTU.
* All management of data transfer between the internal area and the modules and between the internal area and the PLC is **completely transparent**; we mention this for completeness, but **you will not have to deal with it directly.**
* In case of communication failures, SnapTRAINER **automatically** handles the reconnection; thanks to a feature of the Snap7 and SnapMODBUS libraries, this is very fast and does not suffer from the TCP delay in case of an absent partner; in fact, first a PING (which is very fast) is performed and then, if successful, the TCP connection is made.   Even by disconnecting and reconnecting the network cable, the system generally reconnects in 500 ms.

#### Modbus: SnapTRAINER Master - PLC Slave 

In this mode, SnapTRAINER is the active partner, connecting to the PLC and using Modbus functions 3 and 4 to exchange data; registers are transferred one at a time, both because SnapTRAINER does not know the sequencing a priori but mainly because not all PLCs handle multiple transfers.

![](img/comm_2.PNG)

The dashed arrows indicating the transfer from the Register Pack to the modules is handled by the modules themselves.

In the parameterization window we will select Master as the Mode and Modbus TCP or Modbus RTU as the protocol. The address is that of the PLC, the default port is the Modbus port but you can change it if necessary.

Unit ID is the Modbus identifier (the Slave ID), in Modbus TCP it should not make sense; however, check the specifications of your PLC, for example, Arduino OPTA requires this to be 255.

Refresh time indicates the refresh time expressed in milliseconds.

Let’s talk about the connection-related checkbox.

There are two communication errors, the serious one occurring when SnapTRAINER fails to connect with THE PLC or the PLC closes input connections; this is a critical condition for all modules, and all LEDs will turn red.

The second is an addressing error, that is, we are requesting access to a register that is out of range. In this case, the LED for that register on the module will be yellow.

This Checkbox allows SnapTRAINER to disconnect from the PLC even in the presence of errors of the second type. Sometimes, as a result of a logic error, some PLCs tend to "crash," so a disconnect/reconnect cycle (which occurs automatically) can resolve the situation. 

![](img/commsettings_master.png)

#### Modbus: PLC Master - SnapTRAINER Slave

In this mode, the PLC is the active partner, connects to SnapTRAINER and uses Modbus 3 and 16 functions to exchange data; registers, if the PLC allows, can be transferred as a group, SnapTRAINER supports this mode.

![](img/comm_1.PNG)

Again, the dashed arrows indicate the transfer to and from the Register Pack, which is handled directly by the modules.

The parameterization is similar to the previous one; you will obviously have to select the Slave mode.

In this case Address is the address of the PC on which SnapTRAINER runs, and it is the same address you will need to indicate in the PLC parameterization when you go to define the Device.

If you use Modbus TCP, the Slave ID value is indifferent, you can put what you want, in case of Modbus RTU you are going to enter what you have parameterized in the PLC.

Communication, by default, is by reading/writing "Holding Registers." With the Checkbox present, it is possible for the PLC to read the input values as "Input Registers." Some PLCs allow multiple transfer of Input Registers only; if you have performance problems you can use this mode. From the point of view of SnapTRAINER and the modules it is indifferent.

![](img/commsettings_slave.png)

#### S7 Protocol: SnapTRAINER Client - PLC Server

This protocol allows communication with Siemens PLCs to be handled very easily and efficiently.

With the S71200/1500 series PLCs you can also use Modbus; in fact, there are system FBs that handle it. However, I do not recommend this choice, first because you need to call up the FBs, parameterize them, etc. this is not terribly complicated, but if you are a novice it is an unnecessary effort; second because Modbus is handled at the program level, while S7Protocol is handled directly in the firmware by the communication processor, so it is much more efficient; moreover, with S7Protocol there is nothing to do at the program level, only to set some parameters in the communication properties of the PLC (I will show you how to do it in a moment).

For the previous generation PLCs, S7300/400/WinAC the choice is forced: you will have to use S7 Protocol; there are actually Modbus libraries for this series as well but they are chargeable (and a bit annoying to use). So, if you have an old S7300 (equipped with an Ethernet port) salvaged perhaps from some online auction, you can safely use it with SnapTRAINER.

![](img/comm_3.PNG)

With this protocol SnapTRAINER is always the Client.

To adapt the addressing scheme, SnapTRAINER automatically transforms the number of registers into the address of the WORD within a DB (Data Block) according to the formula shown in the image.

This means that you will have to create a DB within which you can insert, in a very flexible way, either Word variables or bit struct variables, the important thing is that the address follows the formula.

![](img/commsettings_s7.png)

To enable absolute addressing manageable by S7 Protocol, it is critical that for S71200 and S71500 PLCs the DBs are not optimized.

![](img/db.png)

And that GET/PUT access be allowed without a password.

![](img/getput.png)

**What pattern to use?**

If you have a **Siemens PLC** the choice is a must, but if you will be using Modbus and your PLC allows you to work both as Master and, as Slave, you will have to decide.

**OpenPLC** (the Windows/Linux runtime) handles both modes well.

**Arduino OPTA** when used as a slave will sometimes disconnect the Master if the refresh rate is a bit high for its liking, also it does not allow multiple transfer of registers. I therefore recommend that you set this PLC as Master and SnapTRAINER as Slave.

The Modbus Slave mode also allows the possibility of having two modules communicate with each other with or without an input connection from a PLC or having multiple PLCs communicate **simultaneously** with SnapTRAINER Slave as it can handle up to 1024 active connections.

## MODULES
Let us now look at the modules available in the first released version.

**Generalities**

All modules consist of a panel and a parameter window.

![](img/module_gen.png)

When SnapTRAINER is offline (i.e., not communicating with the PLC) a button is visible that activates the context menu for deleting, moving, or activating the parameter window.

With SnapTRAINER online, the buttons disappear and the status LEDs (one for each exchanged register) light up to indicate the status of the transfer:

* **Red**: connection problems
* **Yellow**: register addressing problems (probably out of range)
* **Green**: transfer OK.

### Digital I/O module

This module allows 16 input bits and 16 output bits to be exchanged with the PLC.

The upper area is the one dedicated to the inputs (outputs of the PLC), contains 16 LEDs, a display to show the register value in three formats selectable by the buttons below:

* **H**: Hexadecimal (0000..FFFF)
* **D**: Unsigned integer (0..65535)
* **S**: Integer with sign (-32768..+32767)


In addition, there is a bar that graphically represents the input value. 

![](img/digitalio.png)

The lower area is dedicated to outputs (PLC inputs).

* 16 microswitches that allow the output bits to be individually controlled.
* A display showing the value in hexadecimal.
* A bar to represent the value graphically.
* Two buttons, **[Force all OFF]** and **[Force all ON]** that allow you to set all bits simultaneously to zero or one, respectively.
* A hexadecimal keyboard that allows you to set an arbitrary value from 0000 to FFFF and send it to the outputs with the press of the **[OK]** button. This function is useful when we want a set of bits to all arrive at the same time in a given configuration. The small display above the [OK] button will show the set value as it is typed.

This module occupies two registers, one read and one write.

Its parameterization page is as follows:

![](img/digitalio_settings.png)
 
This module supports **immediate write** mode, which can be activated through the CheckBox in the digital outputs section.

Immediate write provides that the value of the outputs is sent **instantaneously** to the PLC with each change, without going through the cyclic communication thread. This can make the PLC program more responsive.

If SnapTRAINER is set as **MODBUS Slave**, this option is not active, as the PLC decides how and when to exchange data.

 
### Analog Input Module

This module allows two channels to be displayed and consider the input values as 16-bit ADC (Analog to Digital Converter) points.

![](img/analogin.png)

A real-time graph allows us to visualize the progress of values over time.

Let’s look at the parameterization right away to understand how visualization occurs.

![](img/analogin_settings.png)

There are two pages, one for each channel, and they are identical, so we analyze only one.

The values of an ADC are expressed in points. However, we are interested in displaying the value of the physical quantity associated with these points.

To do this we need to convert our points to a real (floating point) value, for example, the number 3470, associated with a thermocouple tells us little, it makes much more sense to display 21.7 °C.

Assuming that our sensors are linear (this is the case today; many years ago, when I started in automation, it was necessary to linearize the ADC points with a linear regression), to convert the points we use the equation of the line: **y=mx+n**.

That is, **Actual value = Slope * ADC points + Intercept** 

So, we need to calculate the Slope (slope of the line) and Intercept (point where the line intersects the Y axis).

This calculation SnapTRAINER does automatically by calculating coefficients from two points.

Basically, considering a diagram where on the X axis are the ADC points and on the Y axis are the real values, what we will need to provide are minimum and maximum points and their corresponding real values.

Looking at the previous image, after establishing that the unit of measurement is Volts (it is only for display) we are saying that **zero points** correspond to **0 Volts** and that **65535 points** correspond to **10 Volts**.

Once these values are set, when in a register, for example, there is the value **24903** we will display **3.80 V**.

Of course we have freedom to choose the range, for example we could have determined that in the range 0..65535 the voltage varies from -10.0 V to + 10.0 V and so on.

As already mentioned we can set the unit of measurement, plus there are a couple of "cosmetic" parameters: With **Decimal Places** we can set how many digits are significant after the decimal point; with **Scope Range Max** we set the maximum range for the real-time oscilloscope. We may in fact have a significant 12-bit value, so we can always see the curves scaled correctly.

The **Recalc** button allows us to see the effects on the Point-Gradiance graph of the values we have entered (this is just a display to check that we have set consistent values; the calculation of slope and intercept is done even without pressing the button).

The diagram is automatically scaled to have +/- 10% extension of the entered range and thus easier visualization.

### Analog output module

We can consider this module as the "reciprocal" of the previous one. We provide the setting of a real magnitude and the module will convert it to DAC (Digital to Analog Converter) points.

![](img/analogout.png)

Here again we have two channels, we can set the value by means of a linear slider, or, if we need more precision, by pressing the **[Edit]** button, an Edit field will become visible in which we can directly enter the numerical value.

Let’s look at parameterization.

![](img/analogout_settings.png)

Linearization is done in the same way as the analog inputs module, only here on the X axis we find the actual value, which will be converted to DAC points present on the Y axis.

With the reciprocal parameters to those seen above: 0..10V -> 0..65535, by setting **3.80 V**, we will send the value **24903** to the PLC at the output.

The same applies to the unit of measurement and precision after the decimal point.

Here, however, we find two additional parameters.

A Checkbox that enables immediate write on value change (see Digital I/O module for description).

And the **Safe Value** parameter. This is a safety (or setup) value that the module will use at the start of the simulation or when we press the **[Safe]** button

### Tank Module

This module allows the simulation of a tank. You will see the amount of liquid in the tank vary graphically in relation to what happens to the valves and parameters.

![](img/tank.png)

Our tank system consists of:


* A **container** for liquids
* An **Inlet valve** that allows liquid to enter from above. We can imagine it as a solenoid valve or the electrical control of a lift pump.
* An **Outlet ON/OFF** valve that, when operated, causes liquid to flow out from below, which can become a **proportional valve**.
* Two level sensors: **Minimum** and **Maximum** that have a logical state 1 when covered by liquid. When the tank is empty they will both be at zero, with the liquid between minimum and maximum the minimum sensor will be active; when the liquid reaches the maximum level both sensors will be active.

With one of these modules it is possible to do exercises to manage a tank, or, much more interestingly, it is possible to use several such modules, in cascade or series/parallel, to simulate automatic liquid balancing and distribution systems.

Let’s look at parameterization.

![](img/tank_settings.png)

* **Tank Capacity** indicates the capacity in liters of the tank.
* **Inlet Flow** indicates the flow rate of the inlet flow.
* **Outlet Flow** indicates the flow rate of the outlet flow (if the outlet valve is an ON/OFF solenoid valve).
* **Level Min** and **Level Max** indicate where the sensors are located on the tank in percentage of liquid.
* **Initial Water** indicates what percentage of liquid is present at the beginning of the simulation.

Tank Capacity, Inlet Flow and Outlet Flow together indicate the rate of filling/emptying of the tank.

In reality Inlet Flow is always much larger than Outlet Flow, otherwise the cistern, at full capacity, would empty without ever being able to be filled. 

The internal operation of the module is very simple. 

Assuming both valves open, then we have liquid out and liquid in; at each delta T (sampling interval) the module, knowing the flows, calculates how many liters have gone out and how many have come in so, very simply:   

**Liquid present = previous liquid + Liters IN - Liters OUT**.

The PLC program should turn the Inlet valve on when the liquid falls below the minimum level and turn it off when it reaches the maximum level. Obviously with more tanks it **becomes more interesting**.

You can make the Outlet Valve a proportional valve by passing in the first 14 bits of the input word the value in L/min of the output flow.

If you want this behavior you have to select, in the **Outlet Flow Mode** parameter, the item **"Use PLC Value."**

Finally, on the output (to the PLC), the module provides the amount of liquid present in the first 14 bits of the word.

If we mismanage the Inlet valve, leaving it open all the time, the liquid will overflow and a (virtual) sensor located on the floor will alert us by the words "Flooding." Conversely, if we do not fill the tank properly, another hidden sensor will bring up the words "Empty."

### Pneumatic Cylinders Module

It is an intelligent module that allows up to four pneumatic cylinders to be simulated at the same time; if more are needed, it will be sufficient to insert other modules of the same type.

![](img/cylinders.png)

The movement of each cylinder is completely autonomous, governed by its parameters and the state of the valves that comes of the PLC.

To better understand parameterization, let us briefly look at what a cylinder is and how it works.

![](img/cylinder.png)

The pneumatic cylinder is a mechanical component with pneumatic action; in its most common configuration, it is equipped with two pneumatic ports, one for extension and one for retraction. 

When we insufflate air into the extension port, the inner rod of the cylinder moves outward; the reverse happens when air is insufflated into the retraction port.

The cylinder has two stable positions, the one in which the rod is fully retracted and the one in which the rod is fully extended; any intermediate position is considered indeterminate.

There are also two sensors, integral to the cylinder, that allow the PLC to determine whether the cylinder is extended or retracted.

Basically, an extension movement involves piloting the valve that feeds the extension port and then waiting for the extension sensor to be active. Conversely, when we want to retract the cylinder, we will pilot the retraction solenoid valve and test the home sensor.

To simulate a cylinder, we need **two inputs and two outputs**.

Let us therefore see the parameterization of this module.

![](img/cylinders_settings.png)

We can decide the number of cylinders to be used, four may be too many, for example, suppose we need 7 and we have entered two modules, the second one will have to contain only 3.

Each cylinder module needs two registers, a read register (from the PLC to the Module) that will contain the valve activation bits according to the table shown and a write register (from the Module to the PLC) that will report the status of the sensors to the PLC; only the low byte of each register will be used.

By just assigning addresses to the registers, our module is already able to function. However, to make the simulation more realistic, each cylinder has a set of parameters associated with it that you can change according to your needs.

Stroke indicates the stroke of the stem in millimeters.

**Extension Speed** and **Retraction Speed** indicate the extension and retraction speeds, respectively, expressed in mm/s. In realities these are determined by pneumatic chokes placed on the cylinder ports that serve to vary the airflow and thus the speed.

These parameters we have seen allow us to determine how long it takes a cylinder to make the full stroke, according to the simple formula:

**T[s] = Stroke[mm] / Speed [mm/s]**

**Initial Position** indicates the position of the cylinder at the beginning of the simulation. In reality, when we turn on a machine, we almost never know for sure the state of the cylinders, so **our software must be able to handle a proper reset from an indeterminate situation**. 

Cylinder Type indicates the type of cylinder, which can be double-acting (the one we have seen so far) or spring-return. The latter does not have a retraction light, so when it is not being piloted in extension, it will return automatically. From a piloting point of view, the map does not change; the retraction bit will simply be ignored.

**Extended Sensor** and **Retracted Sensor** indicate the presence or absence of the respective sensors. In reality, it may be the case, for example, that we use a cylinder to clamp a component whose thickness is variable; in this case we cannot insert a "fixed height" sensor, we will therefore be forced to go in time.

Again, in reality, some somewhat "questionable" low-cost automations do not always include the installation of all sensors; this is not a good practice, however, with these parameters we can also prepare for these borderline situations.

Again, the register map does not change when some sensor is absent; its relative bit will always remain at zero.

Finally, **Caption** allows us to assign a name to a cylinder, typically we are going to get it from the pneumatic diagram.

Once the module is parameterized and the simulation is started, the cylinders will move according to the bits coming from the PLC and the parameters set.

![](img/cylinders_running.png)

In the simulation, each cylinder is associated with a status that will be displayed on the right. For the purposes of the control program, this is completely transparent; it serves us only to verify that we are driving the cylinders "properly."

For example, if we drive both valves, extension and retraction, the cylinder locks in the position it is in and its state is **Stalled**, in real applications we should always avoid this condition.

If, on the other hand, we do not drive either valve, the cylinder is in the **Inactive** state; this state should also be avoided, especially with vertical cylinders extending downward; in fact, the cylinders never guarantee perfect pneumatic sealing and the risk is that the cylinder may extend undesirably.

Last note, sensors, as in reality, are associated with a hysteresis fixed in 5 mm.

 
### Generic automatic test unit module

A test unit is an intelligent piece of equipment operated (driven) by a PLC that allows a test of some kind to be performed on a selected component.

There are units for leak testing, electrical insulation, vibration analysis, hydraulic performance, etc., literally hundreds of them.

Leaving aside the characterization units, which perform a series of tests and produce reports, the ones we focus on are the units that test a component and provide a **PASS/FAIL** outcome according to a set recipe. In the case of a rejection, we actually also expect a code associated with it in order to understand what kind of failure occurred in the test and then possibly provide differentiated evacuation paths.

Most of these units, communicate through the exchange of digital signals, once physically wired wires, today they are bits in the field bus.

There are units with very complex protocols that also involve sending prescriptions and collecting data on field buses, a good portion of them, however, use basic protocols that are very similar to each other and very well established.

Our module simulates a test unit, or rather simulates the control protocol, which, although very simple, I have found in dozens of different units.

![](img/testunit.png)

We find three bits from the PLC to the test unit and eight bits from the unit to the PLC.

The protocol is very simple but, like all handshakes, does not lend itself very well to a discursive description, so I show you time diagrams of three cycles.

The first complete, successful test (with the outcome being either good or rejection); the second cycle is interrupted by the PLC via the STOP line; finally, the third cycle is interrupted by the unit due to an internal error: the RESET line must be activated to realign the unit.

**Full cycle**

![](img/cycle_normal.png)

**Interrupted cycle**

![](img/cycle_stopped.png)

**Cycle in error**

![](img/cycle_error.png)

Let’s look at parameterization.

![](img/testunit_settings.png)

Our unit is a "Black Box" that performs a test in a certain interval. The **Test Time** parameter allows this amount to be determined.

The outcome of the test may be PASS/FAIL, with the parameter **Percentage of test passed** we can determine the percentage of good pieces; in the example in the figure, we expect that overall the outcome is OK 75 times out of 100. However, the sequence, PASS test, FAIL test is random.

If the test is failed, a rejection code ranging from 2 to 13 will be associated with it (0 is never used, 1 is the good piece code).

In case of a discard, we can determine whether this code is completely random or sequential, i.e., each time a discard occurs the code will be subsequent to the last one received; after 13 it returns to 2.
On the panel, the bar indicates the passage of time. The **[Force ERROR]** button allows you to cause an internal error, so we can try failure management in our control program.

**Ready/NOT Ready concept**

Any command, including STOP and RESET, are active on the positive side.

**At the end of each command, the test unit goes into the NOT READY state if the command bit is still high.** 

This is a safety to prevent, for example, a START accidentally kept high past the end of the test from launching an unwanted retest.


### Stepper Motor Module

This is a fairly complex module that allows the simulation of a stepper motor either free or connected to a ballscrew transmission mechanism.

![](img/stepper_motor.png)

To understand how it works, it is necessary to look at its parameterization right away.

![](img/stepper_motor_settings.png)

To work, the module needs 5 registers.

**PLC -> Module**

* **Speed Register**: shall contain the frequency i.e., the speed expressed in Step/s.
* **Control Register**: the lower part, the first 8 bits, represents the control word, the upper part will contain the highest 8 bits of the position to be reached.
* **Set Position Register**: contains the lower part of the position to be reached.

The position to be reached, expressed in Steps is a 24-bit number, so we will have a range of 0.. 16,777,215. This is a high number that allows very good positioning accuracy.

**Module -> PLC**

* **Status Register**: the lower part contains the status word; the upper part contains the highest 8 bits of the current motor position.
* **Current Position Register**: contains the lower part of the current position.

The current position, therefore, is also a 24-bit number.

Our module simulates Drive + Engine + Mechanics.

The motor is a stepper-motor selectable, as precision, from a list containing the most popular models: 64, 200, 400, 800, 1000 p/r (Pulses/Revolution).

The Drive is equipped with a 24-bit Resolver and handles the inputs of **HOME, ULS** (Upper Limit Sensor) and **LLS** (Lower Limit Sensor).

The mechanics consist of a carriage running on a ball screw coupled to the motor by a coupling.

Using the **Screw Length** parameter, the length of the screw can be determined for values ranging from 100 to 10000 mm.

Through the Screw Pitch parameter, we can change the screw pitch with values ranging from 2 to 10 mm. Both the length and pitch ranges are commercial values; there is no point in being able to enter fancy numbers or ones that are matched in overly specific custom applications.

Our engine can operate in two ways: 

1. With a displacement mission
2. In Jog

**Missions**

The move mission can be **absolute** or **relative**. In the first case we will tell the Drive the absolute position (in Step) to be reached, in the second case a delta relative to the current position.

A mission is activated by the **START** bit, and the type selection is made by the **ABS/REL** bit (0: absolute, 1: relative).

The position value will always be positive, in case of relative displacement, the direction is controlled by the **DIR** bit, if 1 it will cause CCW (Counterclockwise - negative) movement otherwise the movement will be CW (Clockwise - positive).

There is also a special mission, the **HOMING** triggered by a rising edge of the **HOME** bit: the motor will position itself on the HOME sensor.

**JOG**

Allows free movement of the motor: the motor moves as long as the JOG bit is held high. Its direction is regulated by the **DIR** bit.

**Enabling**

To perform any activity the engine must be enabled, that is, the **ENABLE** bit must be high; we can tell if the engine is properly enabled by going to test the **ENABLED** status bit.

**Fault**

If in a mission the engine reaches one of the safety limit switches, the mission is aborted, the engine stops, and the Drive raises the error bit. It is then necessary to reset it by an edge of the **RESET** bit. The engine, if placed on one of the limit switches, will only accept missions or JOG commands that turn it in the opposite direction.

If a limit switch in JOG is reached, the Drive will stop but the error will not be raised. From this point on, the Drive will only accept missions or JOG commands that turn it in the opposite direction.

In reality, it is possible for a motor to go into error for other reasons, such as overcurrent; our motor is simulated and there is no current, so it is possible to generate an internal error by pressing the **[Force ERR]** button, this allows us to simulate the procedures of reacting he errors and resetting our control software.

**Ready/NOT Ready concept**

Any command, including HOME and RESET, are active on the positive side.

**At the end of each command, the Drive goes into the NOT READY state if the command bit is still high.** 

This is a safety to prevent, for example, a START accidentally kept high past the end of the mission from launching a new, unwanted mission (think relative displacement missions).

**Free motor**

In case of a free motor, not coupled to a linear mechanism:

* The limit switches and the HOME sensor are not managed
* The HOME bit takes on the meaning of **SETREF**: the motor steps are reset instantly.

**Motor module testing**

It is possible to become familiar with this module (as well as others), without having a PLC.

* Select Modbus Slave TCP as the protocol on Localhost address (127.0.0.1)
* Insert one motor module and three Digital I/O modules.
* Set the registers so that each motor input register is associated with a module output register.

![](img/motor_test.png)

### Numeric I/O Module

This module has three 32-bit channels. Two input numbers can be displayed and one can be sent to the PLC. 

![](img/numeric_io.png)

Numbers can be represented in three formats according to the buttons on the right side of each channel (HEX, DEC, FLOAT).

Each channel needs two registers. 

Let’s look at the parameterization.

![](img/numeric_io_settings.png)

For each channel you need to specify the address from the top and the address from the bottom. They are usually contiguous and arranged as in the figure, but you need to do some testing.

Unwanted channels can be disabled.

The Listboxes of the representation set the default, as already explained, you can change it during operation by acting on the buttons.

**Decimals** sets the number of digits after the decimal point when the number is represented in Floating Point.

**Caption** allows a descriptive name to be assigned to each channel.

The output value will be input manually; following pressing the **[EDIT]** button will open an Edit field, in which the number should be entered **in the same format** with which it is displayed.


### Text Module

Allows a text to be associated with a numeric code. 

We have two channels, each capable of representing 256 different strings.

![](img/textmodule.png)

The text can span several lines.

This module needs only one read register; the lower part contains the code for Text A, while the upper part contains the code for Text B.

![](img/textmodule_settings.png)

For each channel, in addition to the editable text list in a grid, we can set the text color, font size, and string alignment.

In addition, we can select a group of cells from the grid of one channel and copy them to the grid of the other channel.

This module also provides an offline testing mode.

![](img/textmodule_offline.png)

When the form is offline there are two numeric fields in which you can enter a number from 0 to 255 and test the correctness of the string and its appearance.

Once online these fields are no longer visible.

### Control Keypad Module

Each small autonomous machine or semi-independent station in a line is equipped with a Control Keypad.

And we have one, too.

![](img/keypad.png)

We have four illuminated buttons, which can be used as pushbuttons or switches, with flashing capability, a three-way selector switch and an emergency mushroom button.

The form is very customizable. 

![](img/keypad_settings.png)

Its parameters are very intuitive.

Of the buttons we can change the lettering, mode (button/switch) and color.

Each button has a light bit and a blink bit associated with its input. If the light bit is on, the button will light; in this condition, if the blink bit is on, the button will blink.

The use of these modes is to highlight the pressure request from the PLC. For example, by convention, in order to gain access to some stations, the request is made by means of a button, which flashes while the station is in motion, but has received the command, and is set to complete the current cycle. When the station is stopped, the button becomes solidly lit, and a further press puts the machinery in the STOP state. At this point (**by hardware safety dissecting the power**) it is possible to enter the station.

To the three-way switch we can associate four labels and the default position it should have at the start of the simulation.

We can associate a custom inscription with the emergency mushroom and determine whether it should be of the NC (Normally Closed - highly recommended default) or NO (Normally Opened) type.

Instead of the selector switch you can display two led lamps (for example to display an outcome), select the Radiobutton "Show Leds" to achieve this.

![](img/keypad_leds.png)

LED lamps can also flash and a label is associated.

## Testing of modules without a PLC

Sometimes it can be convenient to test the various modules without a PLC to check their behavior and parameter settings very quickly. 

This can be accomplished by placing SnapTRAINER in Modbus/TCP Slave mode on LocalHost address 127.0.0.1 and assigning registers in a "cross-over" manner between the modules, as in the figure.


![](img/loopback.png.png)

# Rebuild SnapTRAINER

To rebuild the program you need of some libraries which can be installed via **Online Package Manager** of Lazarus.

I highlighted them in the following image

![](img/libraries.png)

