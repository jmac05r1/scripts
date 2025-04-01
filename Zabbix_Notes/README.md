##  [Zabbix HTTPS Checks via Agent with Macros](Examples/HTTPS_Checks_via_Agent_with_Macros)

This repository provides a clean and scalable way to perform **HTTPS status code checks** using the **Zabbix Agent** and `system.run[]` items.

Ideal for scenarios where:
- You need to monitor **multiple internal HTTPS URLs** per host
- Zabbix Server or Proxy **cannot reach** the target URLs (e.g., custom ports, localhost)
- You want a **template-based, reusable approach** using macros

---



## How It Works

- Zabbix Agent executes `curl` locally to hit HTTPS endpoints
- Status codes are returned (e.g., 200 OK, 403 Forbidden)
- Host-level macros are used to define URLs and ports
- Triggers notify you when response is not as expected

---

##  Requirements

- Zabbix Agent installed on the monitored host
- Curl installed on the host
- Remote commands enabled in `zabbix_agentd.conf`: /etc/zabbix/zabbix_agentd.conf

```ini
EnableRemoteCommands=1
UnsafeUserParameters=1

sudo systemctl restart zabbix-agent
```

---

## Folder Structure

<!-- TREE_START -->
```
Zabbix_Notes
├── Instructions
│   └── HTTPS_Checks_via_Agent_with_Macros
├── README.md
└── Templates
    ├── HTTPS_agent_check
    └── Template_Monitoring_https.xml

3 directories, 4 files
```
Zabbix_Notes
├── Instructions
│   └── HTTPS_Checks_via_Agent_with_Macros
├── README.md
└── Templates
    ├── HTTPS_agent_check
    └── Template_Monitoring_https.xml

3 directories, 4 files
```
.
├── Event_lookup_s3_permissions
│   └── s3_lookup_permission.sh
├── IAM_roles_admin_privileges
│   ├── README.md
│   └── search_iam_roles.sh
├── RDS_minor_upgrades_script
│   ├── README.md
│   └── databases_minor_version.sh
├── Zabbix_Notes
│   ├── Instructions
│   │   └── HTTPS_Checks_via_Agent_with_Macros
│   ├── README.md
│   └── Templates
│       ├── HTTPS_agent_check
│       └── Template_Monitoring_https.xml
├── check_ssmagent_version
│   ├── README.md
│   ├── archived
│   │   ├── oldscript.sh
│   │   └── ssmagentversion.py
│   └── output-ssm-agent-version.sh
├── ipchecker_resources
│   ├── README.md
│   └── ipchecker.sh
├── list_resources_aws
│   ├── README.md
│   ├── list_all_resources.sh
│   └── list_resources_created_by_terraform.sh
├── list_vpc_sg_information
│   ├── README.md
│   ├── list_vpc_sg.sh
│   └── list_vpc_sg_tgw.sh
└── search_ec2_across_regions
    └── ec2_search.sh

13 directories, 22 files
```
