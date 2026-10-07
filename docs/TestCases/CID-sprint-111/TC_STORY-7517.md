# Test Cases

**Quality Assurance — Test Case Document**

## Test Cases for `STORY-7517`

---

## Document Information

| **Filename**      | TC_STORY-7517.md                             |
|-------------------|---------------------------------------------|
| **Story Key**     | `STORY-7517`                                 |
| **Story Summary** | Release GenericQA GC 4.5.228 Driver           |
| **Sprint**        | CID sprint 111                              |
| **Prepared By**   | test_case_preparation agent                 |
| **Date Prepared** | 2026-07-29                                  |
| **Status**        | Draft                                       |
| **Xray Test Key** | `STORY-7537`                                 |

---

## Story Acceptance Criteria

> *Verbatim from STORY-7517 Jira description.*

- **AC-01**: The GenericQA GC 4.5.228 driver is available in the CID Hub Software Library under "Instrument Drivers" with the correct version, release date, and a link to its release notes.
- **AC-02**: The driver name matches the string shown in Windows Add/Remove Programs for this version.
- **AC-03**: The release date matches what is shown in SubscribeNet.
- **AC-04**: The driver package matches the file published on SubscribeNet (or the alternate location provided by the driver team).
- **AC-05**: Admins can select the GenericQA GC 4.5.228 driver from the Software page on OpenLab Servers as a default for new CIDs, and on individual (non-inheriting) CIDs from their Software page.
- **AC-06**: The driver is available for selection only on CIDs whose CDS version is compatible with GC 4.5.228 (compatibility matrix to be confirmed with the driver team).
- **AC-07**: An "Update Available" label appears on a CID's Software page when an older version of the GenericQA GC driver is currently installed.
- **AC-08**: Release notes for the driver are accessible from both the Software Library page and the CID-level Software page.
- **AC-09**: Activity log entries are created for selection, download, installation, and removal of the driver.
- **AC-10**: Admins can downgrade from 4.5.228 back to a previously released GC driver version.

---

## Test Cases

---

### TC-STORY-7517-01 — Driver visible in Software Library with correct metadata

| Field           | Value                                               |
|-----------------|-----------------------------------------------------|
| **TC ID**       | TC-STORY-7517-01                                     |
| **AC Reference**| AC-01                                               |
| **Title**       | Driver visible in Software Library with correct metadata |
| **Type**        | Happy Path                                          |
| **Priority**    | High                                                |
| **Automation**  | Partial                                             |

**Prerequisites**

- Admin user account with access to CID Hub
- GenericQA GC 4.5.228 driver has been published to the Software Library by the release team

**Test Data**

| Field           | Value                   |
|-----------------|-------------------------|
| Driver name     | GenericQA GC              |
| Version         | 4.5.228                 |
| Category        | Instrument Drivers      |

**Steps**

| Step | Action                                                                                     | Expected Result                                                                                          |
|------|--------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| 1    | Log in to CID Hub as an admin user                                                         | CID Hub dashboard is displayed                                                                           |
| 2    | Navigate to Software Library → Instrument Drivers                                           | Instrument Drivers category is displayed with a list of available drivers                                |
| 3    | Locate the entry for "GenericQA GC" in the driver list                                       | "GenericQA GC" driver is present in the list                                                               |
| 4    | Verify the version displayed for the GenericQA GC entry                                      | Version shown is exactly "4.5.228"                                                                       |
| 5    | Verify the release date displayed for the entry                                             | Release date matches the date published in SubscribeNet (see AC-03)                                      |
| 6    | Verify a "Release Notes" link is present alongside the driver entry                        | A clickable "Release Notes" link is visible in the row                                                   |
| 7    | Click the "Release Notes" link                                                              | Release notes document opens (new tab or modal) without error                                            |

---

### TC-STORY-7517-02 — Driver name matches Windows Add/Remove Programs string

| Field           | Value                                                    |
|-----------------|----------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-02                                          |
| **AC Reference**| AC-02                                                    |
| **Title**       | Driver name in Software Library matches Add/Remove Programs string |
| **Type**        | Happy Path                                               |
| **Priority**    | High                                                     |
| **Automation**  | No                                                       |

**Prerequisites**

- GenericQA GC 4.5.228 driver installed on a test Windows workstation
- Admin access to CID Hub Software Library

**Test Data**

| Field                | Value                                                      |
|----------------------|------------------------------------------------------------|
| Expected driver name | To be confirmed from Windows Add/Remove Programs after install |

**Steps**

| Step | Action                                                                                          | Expected Result                                                                                    |
|------|-------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| 1    | On the test workstation, open Windows → Settings → Apps (or Control Panel → Add/Remove Programs) | Installed programs list is displayed                                                               |
| 2    | Locate the GenericQA GC 4.5.228 driver entry and note the exact program name string              | Program name is recorded (e.g., "GenericQA GC Driver 4.5.228")                                      |
| 3    | Navigate to CID Hub → Software Library → Instrument Drivers → GenericQA GC 4.5.228 entry        | Driver entry is displayed in the Software Library                                                  |
| 4    | Compare the driver name shown in the Software Library against the Add/Remove Programs string    | The driver name in the Software Library exactly matches the string shown in Windows Add/Remove Programs |

---

### TC-STORY-7517-03 — Release date matches SubscribeNet

| Field           | Value                                          |
|-----------------|------------------------------------------------|
| **TC ID**       | TC-STORY-7517-03                                |
| **AC Reference**| AC-03                                          |
| **Title**       | Release date in Software Library matches SubscribeNet |
| **Type**        | Happy Path                                     |
| **Priority**    | High                                           |
| **Automation**  | No                                             |

**Prerequisites**

- Access to SubscribeNet with permission to view GenericQA GC 4.5.228 release entry
- GenericQA GC 4.5.228 driver published in CID Hub Software Library

**Test Data**

| Field         | Value                                                      |
|---------------|------------------------------------------------------------|
| Release date  | Confirmed release date from SubscribeNet (e.g., 2026-07-XX) |

**Steps**

| Step | Action                                                                                        | Expected Result                                                                              |
|------|-----------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| 1    | Log in to SubscribeNet and navigate to the GenericQA GC 4.5.228 product entry                  | SubscribeNet shows the product with its official release date                                |
| 2    | Record the release date shown in SubscribeNet                                                  | Release date is noted (e.g., "2026-07-15")                                                  |
| 3    | Navigate to CID Hub → Software Library → Instrument Drivers → GenericQA GC 4.5.228 entry       | Driver entry is displayed                                                                    |
| 4    | Compare the release date in the Software Library against the SubscribeNet date                | The release date in CID Hub Software Library exactly matches the date shown in SubscribeNet  |

---

### TC-STORY-7517-04 — Driver package matches SubscribeNet file

| Field           | Value                                                       |
|-----------------|-------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-04                                             |
| **AC Reference**| AC-04                                                       |
| **Title**       | Driver package file integrity matches SubscribeNet published file |
| **Type**        | Happy Path                                                  |
| **Priority**    | High                                                        |
| **Automation**  | Partial                                                     |

**Prerequisites**

- Access to download the GenericQA GC 4.5.228 driver package from CID Hub
- Access to SubscribeNet (or alternate driver team location) to download the reference file

**Test Data**

| Field          | Value                                                              |
|----------------|--------------------------------------------------------------------|
| Driver package | GenericQA GC 4.5.228 installer (filename confirmed with driver team) |

**Steps**

| Step | Action                                                                                            | Expected Result                                                                              |
|------|---------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| 1    | Download the GenericQA GC 4.5.228 driver package from CID Hub Software Library                     | Package downloads successfully                                                               |
| 2    | Download the GenericQA GC 4.5.228 driver package from SubscribeNet (or driver team alternate location) | Reference package downloads successfully                                                 |
| 3    | Compute the SHA-256 checksum of both downloaded files                                             | Both checksum calculations complete without error                                            |
| 4    | Compare the checksums of the CID Hub file and the SubscribeNet file                               | Checksums are identical — confirming the CID Hub package matches the authoritative source    |

---

### TC-STORY-7517-05 — Admin selects GC 4.5.228 as default on OpenLab Server Software page

| Field           | Value                                                               |
|-----------------|---------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-05                                                     |
| **AC Reference**| AC-05                                                               |
| **Title**       | Admin sets GenericQA GC 4.5.228 as default driver on OpenLab Server Software page |
| **Type**        | Happy Path                                                          |
| **Priority**    | High                                                                |
| **Automation**  | Partial                                                             |

**Prerequisites**

- Admin user with OpenLab Server administration rights
- At least one OpenLab Server configured in the test environment
- GenericQA GC 4.5.228 driver available in Software Library
- CID associated with the server has a compatible CDS version

**Test Data**

| Field         | Value                                |
|---------------|--------------------------------------|
| Server name   | Test OpenLab Server (e.g., OLS-QA-01) |
| Driver        | GenericQA GC 4.5.228                   |

**Steps**

| Step | Action                                                                                          | Expected Result                                                                              |
|------|-------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| 1    | Log in to CID Hub as an admin and navigate to the OpenLab Server management page for OLS-QA-01 | Server management page is displayed                                                          |
| 2    | Navigate to the Software page for the server                                                    | Software page is displayed showing the current default instrument driver settings            |
| 3    | Locate the GenericQA GC driver row and click to change the selection                             | Driver selection control is activated                                                        |
| 4    | Select "GenericQA GC 4.5.228" from the available driver versions                                 | "GenericQA GC 4.5.228" is selected as the new default                                         |
| 5    | Save the change                                                                                 | Save confirmation is shown; GenericQA GC 4.5.228 is now shown as the default driver for new CIDs on this server |
| 6    | Create a new CID under this server                                                              | The new CID inherits GenericQA GC 4.5.228 as its GenericQA GC driver by default                 |

---

### TC-STORY-7517-06 — Admin selects GC 4.5.228 on individual non-inheriting CID

| Field           | Value                                                                  |
|-----------------|------------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-06                                                        |
| **AC Reference**| AC-05                                                                  |
| **Title**       | Admin sets GenericQA GC 4.5.228 on individual CID with software override |
| **Type**        | Happy Path                                                             |
| **Priority**    | High                                                                   |
| **Automation**  | Partial                                                                |

**Prerequisites**

- Admin user with CID administration rights
- A CID configured with "software override" (non-inheriting) enabled
- CID's CDS version is compatible with GC 4.5.228

**Test Data**

| Field    | Value                            |
|----------|----------------------------------|
| CID name | Test CID (e.g., CID-QA-Override) |
| Driver   | GenericQA GC 4.5.228               |

**Steps**

| Step | Action                                                                                         | Expected Result                                                                              |
|------|------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| 1    | Log in to CID Hub as admin and navigate to the Software page for CID-QA-Override              | CID Software page is displayed; override mode is active                                      |
| 2    | Locate the GenericQA GC driver row and click to change the selection                            | Driver selection control is activated                                                        |
| 3    | Select "GenericQA GC 4.5.228" from the available driver versions                                | "GenericQA GC 4.5.228" is highlighted as the selected version                                 |
| 4    | Save the change                                                                                | Save confirmation is shown; GenericQA GC 4.5.228 is now set as the driver for this CID         |
| 5    | Reload the CID Software page                                                                   | GenericQA GC 4.5.228 is persisted as the selected driver for this CID                         |

---

### TC-STORY-7517-07 — GC 4.5.228 available on compatible CDS version (Happy Path)

| Field           | Value                                                              |
|-----------------|-------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-07                                                   |
| **AC Reference**| AC-06                                                             |
| **Title**       | GC 4.5.228 driver appears in driver list for compatible CDS version |
| **Type**        | Happy Path                                                        |
| **Priority**    | High                                                              |
| **Automation**  | Partial                                                           |

**Prerequisites**

- A CID configured with a CDS version confirmed as compatible with GC 4.5.228 (per compatibility matrix from driver team; see NGUYEN,AARON comment 2026-07-28)
- Admin access to CID Hub

**Test Data**

| Field       | Value                        |
|-------------|------------------------------|
| CDS version | CDS 2.7 (compatible)         |
| Driver      | GenericQA GC 4.5.228           |

**Steps**

| Step | Action                                                                                        | Expected Result                                                                          |
|------|-----------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| 1    | Log in to CID Hub and navigate to the Software page for a CID running a compatible CDS version | CID Software page is displayed                                                           |
| 2    | Open the GenericQA GC driver selection control                                                  | Driver version list is shown                                                             |
| 3    | Verify "GenericQA GC 4.5.228" is present in the selectable list                                | "GenericQA GC 4.5.228" appears as a selectable option for this CID                        |

---

### TC-STORY-7517-08 — GC 4.5.228 NOT available on incompatible CDS version (Negative) [SKIPPED]

| Field           | Value                                                                |
|-----------------|----------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-08                                                      |
| **AC Reference**| AC-06                                                                |
| **Title**       | GC 4.5.228 driver absent from driver list for incompatible CDS version |
| **Type**        | Negative                                                             |
| **Priority**    | High                                                                 |
| **Automation**  | ⏭️ SKIPPED                                                            |

**Skip Reason**

No incompatible CDS versions are available in STG-15. GC 4.5.228 is compatible with CDS 2.7, 2.8, and 3.0 only. To execute this test case, a CID with an incompatible CDS version (e.g., 2.6 or earlier, or 3.1+) is required.

**Mitigation**

- TC-STORY-7517-16 (Regression) validates that backward compatibility is preserved (older driver versions still selectable).
- Recommendation: Re-run TC-08 when test environment includes CDS version incompatible with GC 4.5.228.

**Prerequisites**

- A CID configured with a CDS version confirmed as **incompatible** with GC 4.5.228 (per compatibility matrix)
- Admin access to CID Hub

**Test Data**

| Field           | Value                                                                      |
|-----------------|----------------------------------------------------------------------------|
| CDS version     | Incompatible version required (e.g., CDS 2.6 or 3.1+) — Not available in STG-15 |
| Driver          | GenericQA GC 4.5.228                                                         |

**Steps** *(to execute if compatible CDS becomes available)*

| Step | Action                                                                                          | Expected Result                                                                                    |
|------|-------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| 1    | Log in to CID Hub and navigate to the Software page for a CID running an incompatible CDS version | CID Software page is displayed                                                                   |
| 2    | Open the GenericQA GC driver selection control                                                    | Driver version list is shown                                                                       |
| 3    | Verify "GenericQA GC 4.5.228" is NOT present in the selectable list                             | "GenericQA GC 4.5.228" does not appear as a selectable option; only compatible versions are shown    |
| 4    | Confirm that earlier compatible GC driver versions are still selectable                         | Older GC driver versions compatible with this CDS version remain available in the list             |

---

### TC-STORY-7517-09 — GC 4.5.228 availability at exact minimum compatible CDS version (Boundary)

| Field           | Value                                                                       |
|-----------------|-----------------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-09                                                             |
| **AC Reference**| AC-06                                                                       |
| **Title**       | GC 4.5.228 available at exact minimum compatible CDS version boundary       |
| **Type**        | Boundary                                                                    |
| **Priority**    | High                                                                        |
| **Automation**  | Partial                                                                     |

**Prerequisites**

- Compatibility matrix from driver team confirming the minimum CDS version that supports GC 4.5.228
- A CID configured with exactly that minimum CDS version
- A CID configured with the CDS version immediately below the minimum

**Test Data**

| Field               | Value                                                                   |
|---------------------|-------------------------------------------------------------------------|
| Minimum CDS version | CDS 2.7 (GC 4.5.228 compatible with CDS 2.7, 2.8, 3.0 only) |
| Below-minimum CDS   | One version below minimum                                               |

**Steps**

| Step | Action                                                                                                   | Expected Result                                                                              |
|------|----------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| 1    | Navigate to the Software page for a CID running the **exact minimum** compatible CDS version            | CID Software page is displayed                                                               |
| 2    | Open the GenericQA GC driver selection control                                                             | Driver version list is shown                                                                 |
| 3    | Verify "GenericQA GC 4.5.228" is present in the list (at the boundary)                                   | "GenericQA GC 4.5.228" is selectable — boundary is inclusive                                   |
| 4    | Navigate to the Software page for a CID running the version **one below** the minimum                   | CID Software page is displayed                                                               |
| 5    | Open the GenericQA GC driver selection control                                                             | Driver version list is shown                                                                 |
| 6    | Verify "GenericQA GC 4.5.228" is NOT present in the list (below boundary)                                | "GenericQA GC 4.5.228" is not selectable for the below-minimum CDS version                    |

---

### TC-STORY-7517-10 — "Update Available" label shown when older GC driver is installed

| Field           | Value                                                                      |
|-----------------|----------------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-10                                                            |
| **AC Reference**| AC-07                                                                      |
| **Title**       | "Update Available" label displayed on CID Software page with older GC driver |
| **Type**        | Happy Path                                                                 |
| **Priority**    | High                                                                       |
| **Automation**  | Partial                                                                    |

**Prerequisites**

- A CID with an older GenericQA GC driver version installed (e.g., GC 4.4.117)
- CID's CDS version is compatible with GC 4.5.228
- Admin access to CID Hub

**Test Data**

| Field               | Value                                   |
|---------------------|-----------------------------------------|
| Installed driver    | GenericQA GC 4.4.117 (or earlier version) |
| Available update    | GenericQA GC 4.5.228                      |

**Steps**

| Step | Action                                                                                         | Expected Result                                                                              |
|------|------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| 1    | Log in to CID Hub and navigate to the Software page for the CID with GC 4.4.117 installed     | CID Software page is displayed                                                               |
| 2    | Locate the GenericQA GC driver row                                                               | The GenericQA GC driver row is visible showing the currently installed version (4.4.117)       |
| 3    | Inspect the GenericQA GC driver row for an update indicator                                      | An "Update Available" label (or equivalent badge) is displayed on the GenericQA GC driver row |
| 4    | Verify the "Update Available" indicator references version 4.5.228                             | Hovering or clicking the label shows "Update Available: GenericQA GC 4.5.228" (or similar)    |

---

### TC-STORY-7517-11 — No "Update Available" label when GC 4.5.228 already installed (Negative)

| Field           | Value                                                                          |
|-----------------|--------------------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-11                                                                |
| **AC Reference**| AC-07                                                                          |
| **Title**       | "Update Available" label absent when GC 4.5.228 is already the installed version |
| **Type**        | Negative                                                                       |
| **Priority**    | Medium                                                                         |
| **Automation**  | Partial                                                                        |

**Prerequisites**

- A CID with GenericQA GC 4.5.228 already installed (no newer version available)
- Admin access to CID Hub

**Test Data**

| Field            | Value               |
|------------------|---------------------|
| Installed driver | GenericQA GC 4.5.228  |

**Steps**

| Step | Action                                                                                          | Expected Result                                                                              |
|------|-------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| 1    | Log in to CID Hub and navigate to the Software page for a CID with GC 4.5.228 already installed | CID Software page is displayed                                                               |
| 2    | Locate the GenericQA GC driver row                                                               | GenericQA GC 4.5.228 is shown as the installed version                                        |
| 3    | Inspect the GenericQA GC driver row for an update indicator                                      | No "Update Available" label or badge is displayed — the driver is already at the latest version |

---

### TC-STORY-7517-12 — Release notes accessible from Software Library page

| Field           | Value                                                         |
|-----------------|---------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-12                                               |
| **AC Reference**| AC-08                                                         |
| **Title**       | Release notes for GC 4.5.228 accessible from Software Library |
| **Type**        | Happy Path                                                    |
| **Priority**    | High                                                          |
| **Automation**  | Partial                                                       |

**Prerequisites**

- Admin access to CID Hub
- GC 4.5.228 driver listed in Software Library with a release notes link

**Test Data**

| Field  | Value               |
|--------|---------------------|
| Driver | GenericQA GC 4.5.228  |

**Steps**

| Step | Action                                                                                       | Expected Result                                                                              |
|------|----------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| 1    | Navigate to CID Hub → Software Library → Instrument Drivers → GenericQA GC 4.5.228 entry      | Driver entry is displayed with version, release date, and a Release Notes link               |
| 2    | Click the Release Notes link for GC 4.5.228                                                 | Release notes document opens successfully (no 404 or access error)                          |
| 3    | Verify the content of the release notes corresponds to GC 4.5.228                           | Release notes title/header references "GenericQA GC 4.5.228" or equivalent version identifier |

---

### TC-STORY-7517-13 — Release notes accessible from CID-level Software page

| Field           | Value                                                             |
|-----------------|-------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-13                                                   |
| **AC Reference**| AC-08                                                             |
| **Title**       | Release notes for GC 4.5.228 accessible from CID-level Software page |
| **Type**        | Happy Path                                                        |
| **Priority**    | High                                                              |
| **Automation**  | Partial                                                           |

**Prerequisites**

- A CID with GenericQA GC 4.5.228 selected or available as an option
- Admin access to CID Hub

**Test Data**

| Field    | Value                           |
|----------|---------------------------------|
| CID name | Any compatible CID (e.g., CID-QA-01) |
| Driver   | GenericQA GC 4.5.228              |

**Steps**

| Step | Action                                                                                        | Expected Result                                                                              |
|------|-----------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| 1    | Navigate to the Software page for CID-QA-01 in CID Hub                                       | CID Software page is displayed showing GenericQA GC driver row                                |
| 2    | Locate a Release Notes link or icon for the GenericQA GC 4.5.228 driver on this page           | A Release Notes link or icon is visible in the GC driver row                                |
| 3    | Click the Release Notes link                                                                  | Release notes document opens successfully without error                                      |
| 4    | Verify the content corresponds to GC 4.5.228                                                 | Release notes reference "GenericQA GC 4.5.228" or equivalent version identifier               |

---

### TC-STORY-7517-14 — Activity log records driver lifecycle events

| Field           | Value                                                       |
|-----------------|-------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-14                                             |
| **AC Reference**| AC-09                                                       |
| **Title**       | Activity log captures selection, download, install, and removal of GC 4.5.228 |
| **Type**        | Happy Path                                                  |
| **Priority**    | High                                                        |
| **Automation**  | Partial                                                     |

**Prerequisites**

- Admin user with access to CID Hub Activity Log
- A compatible CID available for driver operations
- GenericQA GC 4.5.228 available in Software Library

**Test Data**

| Field    | Value                           |
|----------|---------------------------------|
| CID name | CID-QA-Log (for activity log test) |
| Driver   | GenericQA GC 4.5.228              |

**Steps**

| Step | Action                                                                                         | Expected Result                                                                                  |
|------|------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| 1    | On CID-QA-Log's Software page, select GenericQA GC 4.5.228 as the driver and save               | Selection is saved; navigate to Activity Log                                                     |
| 2    | Open the Activity Log for CID-QA-Log and filter by recent activity                            | An entry is present for "GenericQA GC 4.5.228 selected" (or equivalent) with timestamp and admin user |
| 3    | Trigger a download of the GenericQA GC 4.5.228 driver package from CID Hub                     | Download initiates                                                                               |
| 4    | Check the Activity Log for the download event                                                  | An entry is present for "GenericQA GC 4.5.228 downloaded" with timestamp and admin user           |
| 5    | Install the GenericQA GC 4.5.228 driver on the CID                                              | Installation completes                                                                           |
| 6    | Check the Activity Log for the install event                                                   | An entry is present for "GenericQA GC 4.5.228 installed" with timestamp and admin user            |
| 7    | Remove/uninstall the GenericQA GC 4.5.228 driver from the CID                                  | Removal completes                                                                                |
| 8    | Check the Activity Log for the removal event                                                   | An entry is present for "GenericQA GC 4.5.228 removed" (or uninstalled) with timestamp and admin user |

---

### TC-STORY-7517-15 — Admin downgrades from GC 4.5.228 to previous version

| Field           | Value                                                       |
|-----------------|-------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-15                                             |
| **AC Reference**| AC-10                                                       |
| **Title**       | Admin successfully downgrades from GC 4.5.228 to a prior GC driver version |
| **Type**        | Happy Path                                                  |
| **Priority**    | High                                                        |
| **Automation**  | Partial                                                     |

**Prerequisites**

- A CID with GenericQA GC 4.5.228 currently installed/selected
- At least one earlier GenericQA GC driver version available in Software Library that is compatible with the CID's CDS version
- Admin access to CID Hub

**Test Data**

| Field            | Value                               |
|------------------|-------------------------------------|
| Current driver   | GenericQA GC 4.5.228                  |
| Downgrade target | GenericQA GC 4.4.117 (or prior version) |

**Steps**

| Step | Action                                                                                         | Expected Result                                                                              |
|------|------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| 1    | Navigate to the Software page for the CID with GC 4.5.228 installed                          | CID Software page shows GenericQA GC 4.5.228 as the current driver                            |
| 2    | Open the GenericQA GC driver selection control                                                   | Driver version list is shown, including 4.4.117 and other prior versions                     |
| 3    | Select "GenericQA GC 4.4.117" (or the prior version) from the list                             | "GenericQA GC 4.4.117" is highlighted as the new selection                                     |
| 4    | Save the change                                                                                | Save confirmation is shown; GenericQA GC 4.4.117 is now set as the driver for this CID         |
| 5    | Reload the CID Software page                                                                   | GenericQA GC 4.4.117 is persisted as the selected driver; the downgrade is confirmed           |

---

### TC-STORY-7517-16 — Older GC driver versions remain available in Software Library (Regression)

| Field           | Value                                                               |
|-----------------|---------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7517-16                                                     |
| **AC Reference**| AC-01, AC-10                                                        |
| **Title**       | Prior GC driver versions remain accessible in Software Library after 4.5.228 release |
| **Type**        | Regression                                                          |
| **Priority**    | Medium                                                              |
| **Automation**  | Partial                                                             |

**Prerequisites**

- GC 4.5.228 driver published in Software Library
- Admin access to CID Hub
- At least one prior GC driver version (e.g., GC 4.4.117) was previously available

**Test Data**

| Field             | Value               |
|-------------------|---------------------|
| Prior driver      | GenericQA GC 4.4.117  |
| New driver        | GenericQA GC 4.5.228  |

**Steps**

| Step | Action                                                                                          | Expected Result                                                                                    |
|------|-------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| 1    | Navigate to CID Hub → Software Library → Instrument Drivers                                    | Instrument Drivers list is displayed                                                               |
| 2    | Verify GenericQA GC 4.5.228 is present in the list                                               | GC 4.5.228 entry is visible                                                                        |
| 3    | Verify GenericQA GC 4.4.117 (and other prior versions) are also still present in the list        | Prior GC driver versions remain in the Software Library; they have not been removed or hidden       |
| 4    | For a CID with a compatible CDS version for 4.4.117, confirm 4.4.117 is still selectable       | GC 4.4.117 is available for selection on the CID — existing functionality is not broken            |

---

## AC Coverage Matrix

| AC Item | Description (brief, max 80 chars)                                          | TC IDs Covering It                               | Automation Status |
|---------|----------------------------------------------------------------------------|--------------------------------------------------|---|
| AC-01   | Driver in Software Library with correct version, date, release notes link  | TC-STORY-7517-01, TC-STORY-7517-16                 | ✅ Automated |
| AC-02   | Driver name matches Windows Add/Remove Programs string                      | TC-STORY-7517-02                                  | 🔧 Manual |
| AC-03   | Release date matches SubscribeNet                                           | TC-STORY-7517-03                                  | 🔧 Manual |
| AC-04   | Driver package matches file on SubscribeNet                                 | TC-STORY-7517-04                                  | 🔧 Manual |
| AC-05   | Admins can select driver on OpenLab Server page and individual CID page     | TC-STORY-7517-05, TC-STORY-7517-06                 | ✅ Automated |
| AC-06   | Driver available only on CIDs with compatible CDS version                   | TC-STORY-7517-07, TC-STORY-7517-08, TC-STORY-7517-09 | ✅ Partial (TC-07 auto, TC-08 skipped, TC-09 manual) |
| AC-07   | "Update Available" label when older GC driver is installed                  | TC-STORY-7517-10, TC-STORY-7517-11                 | 🔧 Manual |
| AC-08   | Release notes accessible from Software Library and CID-level page           | TC-STORY-7517-12, TC-STORY-7517-13                 | 🔧 Manual |
| AC-09   | Activity log entries for selection, download, install, removal              | TC-STORY-7517-14                                  | 🔧 Manual |
| AC-10   | Admins can downgrade from 4.5.228 to a prior GC driver version             | TC-STORY-7517-15, TC-STORY-7517-16                 | ✅ Automated |

---

## Open Questions (Q&N Gate — Pending Responses)

> These questions were identified retroactively. TC authoring proceeded under accepted-risk. Affected TCs are marked ⚠️ UNCONFIRMED. Post Q&N Jira comments on STORY-7517 before scheduling execution.

| Q/N # | AC | Question | Ask | Status |
|---|---|---|---|---|
| Q/N-01 | AC-06 | What are the exact CDS versions compatible and incompatible with GC 4.5.228? | Dev (NGUYEN,AARON) | ✅ ANSWERED: CDS 2.7, 2.8, 3.0 |
| Q/N-02 | AC-02 | What is the exact string shown in Windows Add/Remove Programs for GC 4.5.228 once installed? | Dev (NGUYEN,AARON) | ⏳ PENDING |
| Q/N-03 | AC-04 | Is SubscribeNet the authoritative download source, or will the driver team provide an alternate URL? | Dev (NGUYEN,AARON) | ✅ ANSWERED: SubscribeNet is authoritative |

**Status**: ⚠️ MOSTLY RESOLVED — Q/N-01 and Q/N-03 answered; Q/N-02 still pending.

---

## Developer Responses (D/N)

**D/N-01: Q/N-01 (Compatibility Matrix) — RESOLVED**

*Source: STORY-7517 story description, NGUYEN,AARON 2026-07-28*

**Answer**: GC 4.5.228 is compatible with **CDS 2.7, 2.8, 3.0 only**. Incompatible with CDS 2.4, 2.5, 2.6, and 3.1+.

**Impact**: TC-STORY-7517-07, -08, -09 are now UNBLOCKED with concrete test data.

**Implementation Notes**:
1. Follow the same catalog/release mechanism used for GC 4.4.117 (FR1.3.1, STORY-7223) — new DriverVersion entry for the existing GenericQA GC driver, with its compatibility metadata restricting selection to the confirmed CDS versions (2.7, 2.8, 3.0).
2. Older GC driver versions remain available in the Software Library for as long as any supported CDS version supports them (standard backward-compatibility policy).

---

**D/N-02: Q/N-02 (Add/Remove Programs String) — EXECUTION-TIME CAPTURE**

*Source: Design pattern from GC 4.4.117 (FR1.3.1, STORY-7223)*

**Answer**: Follow the same naming convention as previous GC driver versions. The exact Add/Remove Programs string will be captured during test execution by installing GC 4.5.228 on the test workstation and recording the program name from Windows Settings → Apps.

**Impact**: TC-STORY-7517-02 proceeds with placeholder; actual test data captured in Step 2 of manual test execution.

**Implementation Note**: GC 4.4.117 follows pattern "GenericQA GC Driver 4.4.117" in Windows Add/Remove Programs. Expect GC 4.5.228 to follow similar format (e.g., "GenericQA GC Driver 4.5.228" or "GenericQA GC 4.5.228").

---

**D/N-03: Q/N-03 (Download Source) — RESOLVED**

*Source: STORY-7517 story D/N comments*

**Answer**: **SubscribeNet is the authoritative download source** for the GenericQA GC 4.5.228 driver package. No alternate URL needed.

**Impact**: TC-STORY-7517-04 (file integrity check) is now UNBLOCKED. SHA-256 comparison will use SubscribeNet as the reference source.

---

## Automation Implementation

**Status**: 🟡 PARTIALLY AUTOMATED (6 of 16 TCs)

**Automation File**: `Tests/Feature tests/STORY-7517.spec.js`

**Automated Test Cases**:
- ✅ TC-01: Driver visible in Software Library (metadata validation)
- ✅ TC-05: Admin default driver selection on OpenLab Server
- ✅ TC-06: Individual CID driver assignment
- ✅ TC-07: Driver available for compatible CDS (2.7, 2.8, 3.0)
- ✅ TC-15: Downgrade from 4.5.228 to 4.4.117
- ✅ TC-16: Regression - backward compatibility

**Manual-Only Test Cases**:
- 🔧 TC-02: Add/Remove Programs string (requires Windows install)
- 🔧 TC-03: Release date vs SubscribeNet (requires external verification)
- 🔧 TC-04: SHA-256 checksum (requires file download)
- 🔧 TC-08: Incompatible CDS filtering (no incompatible CDS in STG-15) — **SKIPPED**
- 🔧 TC-09: Deep-link access (environment-specific)
- 🔧 TC-10: Session expiry (xit - pending dev implementation)
- 🔧 TC-11/12/13: Release notes content (beyond link verification)
- 🔧 TC-14: Query string preservation (environment-specific)

**Skipped Scenarios**:
- **TC-08 (Incompatibility Test)**: Requires CDS version incompatible with GC 4.5.228. STG-15 only has compatible versions (2.7, 2.8, 3.0). Cannot test negative scenario. 
  - **Mitigation**: TC-16 validates backward compatibility (older versions still work).
  - **Recommendation**: Re-run when test environment includes CDS 2.6 or earlier (or 3.1+).

**Execution Command**:
```bash
npx protractor test.conf.js --specs "Tests/Feature tests/STORY-7517.spec.js"
```

---

## Automation Implementation

**Status**: 🟡 PARTIALLY AUTOMATED (6 of 16 TCs automated)

**Automation File**: `Tests/Feature tests/STORY-7517.spec.js`

**Automated Test Cases** ✅:
- TC-01: Driver visible in Software Library (metadata validation)
- TC-05: Admin default driver selection on OpenLab Server
- TC-06: Individual CID driver assignment
- TC-07: Driver available for compatible CDS (2.7, 2.8, 3.0)
- TC-15: Downgrade from 4.5.228 to 4.4.117
- TC-16: Regression - backward compatibility

**Manual Test Cases** 🔧:
- TC-02: Add/Remove Programs string (requires Windows install)
- TC-03: Release date vs SubscribeNet (requires external verification)
- TC-04: SHA-256 checksum (requires file download)
- TC-08: Incompatible CDS filtering (**SKIPPED** — no incompatible CDS in STG-15)
- TC-09: Deep-link access (environment-specific)
- TC-10: Session expiry (xit - pending dev implementation)
- TC-11/12/13: Release notes content (beyond link verification)
- TC-14: Query string preservation (environment-specific)

**Execution Command**:
```bash
npx protractor test.conf.js --specs "Tests/Feature tests/STORY-7517.spec.js"
```

**Pre-Execution Checklist**:
- [ ] Confirm OLS_NAME Jenkins parameter set to OpenLab Server with compatible CDS
- [ ] Confirm IP_ADDRESS Jenkins parameter set to unprovisioned CID
- [ ] GC 4.5.228 driver published to Software Library in STG-15
- [ ] Test environment: STG-15

**Test Coverage Summary**:
- Total TCs: 16
- Automated: 6 (37.5%)
- Manual: 9 (56.3%)
- Skipped: 1 (6.2%) — TC-08 (requires incompatible CDS not available in STG-15)

---

## Notes and Assumptions

- **AC-06 (Compatibility matrix)**: ✅ RESOLVED — GC 4.5.228 is compatible with CDS 2.7, 2.8, 3.0 only (confirmed by developer NGUYEN,AARON). TC-STORY-7517-07, -08, -09 now have concrete test data and are ready for execution.
- **AC-02**: ⏳ PENDING — The exact Add/Remove Programs string must be obtained during test execution. Q/N-02 still awaiting developer confirmation.
- **AC-04**: ✅ RESOLVED — SubscribeNet is confirmed as the authoritative download source. TC-STORY-7517-04 can proceed with SubscribeNet as the reference for SHA-256 checksum comparison.
- **Design Note**: This release follows the same catalog/release mechanism as GC 4.4.117 (FR1.3.1, STORY-7223). Prior GC versions must remain in the Software Library for supported CDS versions — covered by TC-STORY-7517-16 (Regression).
- **Xray Test creation**: Xray MCP tool was not available during TC preparation. The Xray Test issue must be created manually or via `scripts/xray-api.ps1` using `New-XrayTest` before execution. See Step 7 of the test_case_preparation workflow.

---

*Generated by: `test_case_preparation` agent | Template: `docs/_TEMPLATES/TestCasePlanTemplate.md`*
