# AuraDrive

# Safe Autonomous Navigation Using Mobile Phone Measurements

## 🔎 Pain Points & Core Understanding

**Exact Problem:**  
Develop a low-cost, sensor-light positioning system for vehicles—leveraging raw GNSS and inertial data from Android phones—to detect proximity, predict collisions, and provide real-time warnings without expensive LIDAR or dedicated proximity sensors.

**Root Causes:**  
- High cost and complexity of LIDAR/RADAR systems  
- Limited infrastructure for V2V (vehicle-to-vehicle) communication  
- GNSS signal degradation in urban canyons and indoors  
- Lack of fusion algorithms optimized for smartphone sensor noise

**Primary Stakeholders:**  
- Commuters and fleet operators  
- Automotive OEMs targeting cost-sensitive markets  
- Smart city planners and traffic authorities  
- Hackathon participants evaluating feasibility of mobile-based sensing

**Current Challenges & Inefficiencies:**  
- Smartphone GNSS and IMU measurements suffer multipath, drift, and latency  
- Ad-hoc data sharing (Bluetooth/Wi-Fi) has bandwidth and range limits  
- Centralized servers introduce latency and single-point failures  
- Indoor and urban environments lack reliable reference signals

***

## ⚙️ Feasibility of Execution

**Prototype in Timeline?**  
Yes—basic V2V data exchange and collision warning prototypes can be built within 48–72 hours using available SDKs.

**Technical Requirements:**  
- Android APIs: GNSS Raw Measurements, SensorManager (accelerometer, gyroscope)  
- Networking: BLE mesh or Wi-Fi Direct for peer discovery and data exchange  
- Optional: Lightweight backend (Node.js/Flask) for coordination if direct mesh is insufficient  
- Data fusion libraries: RTKLIB or custom Extended Kalman Filter (EKF)  
- Hardware: ≥ 3 Android phones; portable chargers; tripods for static base stations

**Potential Blockers:**  
- **Data Availability:** Inconsistent GNSS quality on low-end devices  
- **Regulations:** Spectrum limits for ad-hoc radio; privacy of location sharing  
- **Scaling:** Real-time mesh network reliability with > 10 nodes  
- **Indoor Signals:** Absence of GNSS—requires use of phones as anchor beacons

**MVP to Impress Evaluators:**  
- Real-time proximity alerts between two moving phones  
- Dynamic adjustment of safe-distance thresholds based on fused sensor accuracy  
- Optional indoor demo: static phones broadcasting pseudorange corrections

***

## 🌍 Impact & Relevance

**Beneficiaries:**  
- Everyday drivers using cost-effective ADAS features  
- Fleet managers optimizing routing and collision risk  
- Government bodies piloting smart traffic solutions  
- Students and researchers exploring mobile-centric navigation

**Real-World Impact:**  
- **Economic:** Reduces entry barrier for ADAS, enabling mass adoption  
- **Social:** Lowers accident risk in dense urban and rural settings  
- **Environmental:** Improves traffic flow, lowering idle emissions  

**Scalability:**  
- From hackathon prototype to city-wide fleet trials  
- Integration into ride-sharing apps and logistics platforms  
- Potential national-level smart roadway deployment via public–private partnerships

**Evaluator Importance:**  
- Addresses cost and accessibility of autonomous safety  
- Aligns with “Smart Vehicles” theme and ISRO’s GNSS expertise  
- Demonstrates innovative use of existing smartphone infrastructure

***

## 💡 Scope of Innovation (Existing Solutions)

| Solution Type            | Examples                                  | Limitations                                  |
|--------------------------|-------------------------------------------|----------------------------------------------|
| Smartphone GNSS Apps     | GNSS Viewer Pro, InertialNav SDK          | Lack collision-prediction, no mesh sharing   |
| V2V Communication        | DSRC modules, 5G C-V2X trials             | Expensive hardware, network dependency       |
| Research Prototypes      | RTK-on-Wheels, UWB indoor positioning  | Requires anchors/UWB tags, limited outdoor   |

**Innovative Enhancements:**  
- **Distributed EKF Fusion:** Merge raw GNSS + IMU + peer corrections without server  
- **Adaptive Safety Envelope:** Real-time adjustment of warning thresholds based on confidence metrics  
- **Hybrid Mesh Networking:** Seamless switch between BLE and Wi-Fi Direct for robust connectivity  
- **Augmented Reality Overlay:** Display collision warnings on live camera feed  

***

## 🧩 Clarity of Problem Statement

**Deliverables:**  
- Algorithm for sensor fusion and relative positioning  
- Real-time data sharing module (peer-to-peer or serverless mesh)  
- Mobile application prototype with proximity/collision alerts  
- Indoor navigation demo using phone-based base stations

**Common Misinterpretations:**  
- Assuming centralized cloud is mandatory  
- Confusing raw data access with processed GNSS fixes  
- Overlooking IMU drift correction

**Framing for Evaluators:**  
- Emphasize decentralization (“no server required”)  
- Highlight quantitative metrics: positioning accuracy vs. speed  
- Show clear module separation: sensing, networking, fusion, UI

***

## 🎯 Evaluator’s Perspective

**Judging Criteria:**  
- **Uniqueness:** Novelty of serverless fusion approach  
- **Feasibility:** Working prototype and modular code  
- **Sustainability:** Scalability and low maintenance  
- **Impact:** Measured reduction in collision risk in tests  
- **Completeness:** From raw data capture to alert UI

**Red Flags to Avoid:**  
- Lack of privacy safeguards for location sharing  
- Insufficient testing in realistic scenarios  
- Overly complex architecture that can’t be demoed

***

## 👥 Strategy for Team Fit & Execution

**Recommended Skill Sets:**  
- **Backend/Networking:** P2P mesh design, lightweight servers  
- **Frontend/Mobile:** Android SDK, UI/UX design  
- **Algorithms/AI:** Sensor fusion, Kalman filters, ML-based anomaly detection  
- **Hardware/Test:** Setup of static base stations, field trials  

**Ideal Team Ratio:**  
- 1 Networking Engineer  
- 1 Mobile Developer  
- 1 Algorithm Specialist  
- 1 UI/UX & QA Engineer  

**Step-by-Step Approach:**  
1. **Research & Ideation:** Review smartphone GNSS raw API; study BLE mesh tutorials  
2. **Networking Prototype:** Establish basic P2P data exchange between two phones  
3. **Fusion Engine:** Implement EKF merging raw GNSS + IMU; test in static scenario  
4. **Collision Logic:** Define safety thresholds; simulate crossing trajectories  
5. **UI & Alerts:** Build mobile UI to visualize proximity warnings  
6. **Indoor Demo:** Deploy static phones as anchors; validate error reduction  
7. **Polish & Presentation:** Record demo videos; prepare slide deck emphasizing metrics  

***

This structured breakdown ensures clarity, feasibility, and distinguishes the solution through technical innovation and impact.
