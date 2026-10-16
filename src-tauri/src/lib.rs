use chrono::Utc;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::fs;
use std::net::UdpSocket;
use std::path::PathBuf;
use sysinfo::System;
use tauri::Manager;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoreIdentity {
    pub app_name: String,
    pub package_identity_name: String,
    pub publisher: String,
    pub publisher_display_name: String,
    pub package_family_name: String,
    pub package_sid: String,
    pub store_id: String,
    pub store_protocol_url: String,
    pub store_web_url: String,
    pub version: String,
    pub bundle_targets: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemDiagnostics {
    pub os_name: String,
    pub arch: String,
    pub hostname: String,
    pub cpu_cores: usize,
    pub cpu_brand: String,
    pub total_memory_mb: u64,
    pub used_memory_mb: u64,
    pub memory_usage_percent: f64,
    pub local_ip: String,
    pub cache_path: String,
    pub cache_size_bytes: u64,
    pub appwrite_endpoint: String,
    pub appwrite_project_id: String,
    pub lan_livekit_node: String,
    pub lan_livekit_ready: bool,
    pub timestamp: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OfflineCacheResult {
    pub status: String,
    pub synced_at: String,
    pub path: String,
    pub bytes_written: usize,
    pub records_count: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LanConferenceDescriptor {
    pub session_id: String,
    pub room_name: String,
    pub course_code: String,
    pub host_ip: String,
    pub ws_url: String,
    pub webrtc_port: u16,
    pub token_signature: String,
    pub mode: String,
    pub started_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AttendanceQrPayload {
    pub qr_id: String,
    pub course_id: String,
    pub session_type: String,
    pub issued_at: String,
    pub expires_at: String,
    pub signature: String,
    pub encoded_payload: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExportReportResult {
    pub file_path: String,
    pub format: String,
    pub rows_exported: usize,
    pub bytes_written: usize,
    pub exported_at: String,
}

fn detect_local_ip() -> String {
    if let Ok(socket) = UdpSocket::bind("0.0.0.0:0") {
        if socket.connect("8.8.8.8:80").is_ok() {
            if let Ok(addr) = socket.local_addr() {
                return addr.ip().to_string();
            }
        }
    }
    "192.168.1.100".to_string()
}

fn get_cache_file_path(app: &tauri::AppHandle) -> PathBuf {
    let base = app
        .path()
        .app_data_dir()
        .unwrap_or_else(|_| std::env::temp_dir().join("uniflow-work"));
    let _ = fs::create_dir_all(&base);
    base.join("uniflow_offline_cache.json")
}

#[tauri::command]
fn get_store_identity() -> StoreIdentity {
    StoreIdentity {
        app_name: "Uniflow work".to_string(),
        package_identity_name: "KERNELFORGE.Uniflowwork".to_string(),
        publisher: "CN=200A91F7-4B15-441F-9332-83F216885B09".to_string(),
        publisher_display_name: "KERNEL FORGE".to_string(),
        package_family_name: "KERNELFORGE.Uniflowwork_3wyzhk1x8xr0a".to_string(),
        package_sid: "S-1-15-2-3173161051-1525954667-3862484852-2055131400-1678586278-65818988-3190942280".to_string(),
        store_id: "9NGZKFGK98K6".to_string(),
        store_protocol_url: "ms-windows-store://pdp/?productid=9NGZKFGK98K6".to_string(),
        store_web_url: "https://apps.microsoft.com/detail/9NGZKFGK98K6".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        bundle_targets: vec![
            "msi (Windows WiX)".to_string(),
            "nsis (.exe Windows Installer)".to_string(),
            "msix (AppxManifest Microsoft Store)".to_string(),
            "deb (Debian/Ubuntu)".to_string(),
            "appimage (Universal Linux)".to_string(),
            "rpm (Fedora/RHEL)".to_string(),
        ],
    }
}

#[tauri::command]
fn get_system_diagnostics(app: tauri::AppHandle) -> SystemDiagnostics {
    let mut sys = System::new_all();
    sys.refresh_memory();
    sys.refresh_cpu();

    let total_memory_mb = sys.total_memory() / (1024 * 1024);
    let used_memory_mb = sys.used_memory() / (1024 * 1024);
    let memory_usage_percent = if total_memory_mb > 0 {
        ((used_memory_mb as f64 / total_memory_mb as f64) * 1000.0).round() / 10.0
    } else {
        0.0
    };

    let cpu_cores = sys.cpus().len().max(1);
    let cpu_brand = sys
        .cpus()
        .first()
        .map(|c| c.brand().to_string())
        .unwrap_or_else(|| "x86_64 Multi-Core Processor".to_string());

    let local_ip = detect_local_ip();
    let cache_file = get_cache_file_path(&app);
    let cache_size_bytes = fs::metadata(&cache_file).map(|m| m.len()).unwrap_or(0);

    SystemDiagnostics {
        os_name: std::env::consts::OS.to_string(),
        arch: std::env::consts::ARCH.to_string(),
        hostname: System::host_name().unwrap_or_else(|| "uy1-campus-workstation".to_string()),
        cpu_cores,
        cpu_brand,
        total_memory_mb,
        used_memory_mb,
        memory_usage_percent,
        local_ip: local_ip.clone(),
        cache_path: cache_file.to_string_lossy().to_string(),
        cache_size_bytes,
        appwrite_endpoint: "https://vps.kernelforge.codes/v1".to_string(),
        appwrite_project_id: "uniflow".to_string(),
        lan_livekit_node: format!("ws://{}:7880", local_ip),
        lan_livekit_ready: true,
        timestamp: Utc::now().to_rfc3339(),
    }
}

#[tauri::command]
fn sync_offline_cache(
    app: tauri::AppHandle,
    payload: serde_json::Value,
) -> Result<OfflineCacheResult, String> {
    let cache_file = get_cache_file_path(&app);
    let serialized = serde_json::to_string_pretty(&payload).map_err(|e| e.to_string())?;
    fs::write(&cache_file, serialized.as_bytes()).map_err(|e| e.to_string())?;

    let records_count = payload
        .as_object()
        .map(|obj| obj.len())
        .unwrap_or(1);

    Ok(OfflineCacheResult {
        status: "SYNCHRONIZED".to_string(),
        synced_at: Utc::now().to_rfc3339(),
        path: cache_file.to_string_lossy().to_string(),
        bytes_written: serialized.len(),
        records_count,
    })
}

#[tauri::command]
fn start_lan_conference(room_name: String, course_code: String) -> LanConferenceDescriptor {
    let ip = detect_local_ip();
    let now = Utc::now();
    let raw = format!("UNIFLOW-LAN|{}|{}|{}|{}", room_name, course_code, ip, now.timestamp());
    let mut hasher = Sha256::new();
    hasher.update(raw.as_bytes());
    let signature = hex::encode(hasher.finalize());

    LanConferenceDescriptor {
        session_id: format!("LAN-{}-{}", course_code.to_uppercase(), &signature[..8].to_uppercase()),
        room_name: room_name.clone(),
        course_code,
        host_ip: ip.clone(),
        ws_url: format!("ws://{}:7880/rtc/{}", ip, room_name.to_lowercase().replace(' ', "-")),
        webrtc_port: 7881,
        token_signature: signature[..24].to_string(),
        mode: "CAMPUS_LAN_HYBRID_WEBRTC".to_string(),
        started_at: now.to_rfc3339(),
    }
}

#[tauri::command]
fn generate_attendance_qr(course_id: String, session_type: String) -> AttendanceQrPayload {
    let now = Utc::now();
    let expires = now + chrono::Duration::minutes(15);
    let seed = format!(
        "KERNELFORGE.Uniflowwork|9NGZKFGK98K6|{}|{}|{}",
        course_id,
        session_type,
        now.timestamp()
    );
    let mut hasher = Sha256::new();
    hasher.update(seed.as_bytes());
    let signature = hex::encode(hasher.finalize());
    let qr_id = format!("UF-QR-{}-{}", course_id.to_uppercase(), &signature[..6].to_uppercase());
    let encoded_payload = format!(
        "uniflow://attendance?id={}&course={}&type={}&ts={}&sig={}",
        qr_id,
        course_id,
        session_type,
        now.timestamp(),
        &signature[..16]
    );

    AttendanceQrPayload {
        qr_id,
        course_id,
        session_type,
        issued_at: now.to_rfc3339(),
        expires_at: expires.to_rfc3339(),
        signature: signature[..32].to_string(),
        encoded_payload,
    }
}

#[tauri::command]
fn export_report_file(
    app: tauri::AppHandle,
    title: String,
    format: String,
    rows: Vec<serde_json::Value>,
) -> Result<ExportReportResult, String> {
    let base = app
        .path()
        .app_data_dir()
        .unwrap_or_else(|_| std::env::temp_dir().join("uniflow-work"));
    let exports_dir = base.join("exports");
    let _ = fs::create_dir_all(&exports_dir);

    let safe_title = title
        .chars()
        .map(|c| if c.is_alphanumeric() || c == '-' || c == '_' { c } else { '_' })
        .collect::<String>();
    let ext = if format.to_lowercase() == "json" { "json" } else { "csv" };
    let file_path = exports_dir.join(format!("{}_{}.{}", safe_title, Utc::now().timestamp(), ext));

    let content = if ext == "json" {
        serde_json::to_string_pretty(&rows).map_err(|e| e.to_string())?
    } else {
        let mut csv_lines = Vec::new();
        if let Some(first) = rows.first().and_then(|v| v.as_object()) {
            let headers: Vec<String> = first.keys().cloned().collect();
            csv_lines.push(headers.join(","));
            for row in &rows {
                if let Some(obj) = row.as_object() {
                    let vals: Vec<String> = headers
                        .iter()
                        .map(|k| {
                            obj.get(k)
                                .map(|v| v.to_string().replace('"', ""))
                                .unwrap_or_default()
                        })
                        .collect();
                    csv_lines.push(vals.join(","));
                }
            }
        }
        csv_lines.join("\n")
    };

    fs::write(&file_path, content.as_bytes()).map_err(|e| e.to_string())?;

    Ok(ExportReportResult {
        file_path: file_path.to_string_lossy().to_string(),
        format: ext.to_uppercase(),
        rows_exported: rows.len(),
        bytes_written: content.len(),
        exported_at: Utc::now().to_rfc3339(),
    })
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            get_store_identity,
            get_system_diagnostics,
            sync_offline_cache,
            start_lan_conference,
            generate_attendance_qr,
            export_report_file
        ])
        .run(tauri::generate_context!())
        .expect("error while running Uniflow work Tauri application");
}
