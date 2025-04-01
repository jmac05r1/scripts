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
<!-- TREE_END -->
