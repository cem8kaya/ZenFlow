//
//  BackupView.swift
//  ZenFlow
//
//  Copyright © 2026 ZenFlow. All rights reserved.
//
//  Back up the user's data to a JSON file (share sheet: Files, iCloud Drive,
//  AirDrop, Mail...) and restore it, for example on a new phone.
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupView: View {
    @State private var backupURL: URL?
    @State private var backupSummary: ZenBackup.Summary?
    @State private var showImporter = false
    @State private var pendingRestore: ZenBackup?
    @State private var errorMessage: String?
    @State private var showRestoreDone = false

    var body: some View {
        List {
            // MARK: Create

            Section {
                Button {
                    createBackup()
                } label: {
                    Label(String(localized: "backup_create", defaultValue: "Yedek Oluştur", comment: "Create backup button"), systemImage: "square.and.arrow.down.on.square")
                }

                if let backupURL {
                    ShareLink(item: backupURL) {
                        Label(String(localized: "backup_share", defaultValue: "Yedeği Kaydet veya Paylaş", comment: "Share backup button"), systemImage: "square.and.arrow.up")
                    }

                    if let backupSummary {
                        Text(String(localized: "backup_ready", defaultValue: "Yedek hazır: \(backupSummary.sessionCount) seans, \(backupSummary.totalMinutes) dakika.", comment: "Backup ready message"))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(String(localized: "backup_section_create", defaultValue: "Yedekle", comment: "Backup section header"))
            } footer: {
                Text(String(localized: "backup_create_footer", defaultValue: "Seanslarını, serini, rozetlerini, ruh hali kayıtlarını ve özelleştirmelerini tek bir dosyada saklar. Dosyayı iCloud Drive'a kaydedebilirsin.", comment: "Backup create footer"))
            }

            // MARK: Restore

            Section {
                Button {
                    showImporter = true
                } label: {
                    Label(String(localized: "backup_restore", defaultValue: "Yedekten Geri Yükle", comment: "Restore backup button"), systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text(String(localized: "backup_section_restore", defaultValue: "Geri Yükle", comment: "Restore section header"))
            } footer: {
                Text(String(localized: "backup_restore_footer", defaultValue: "Geri yükleme, bu cihazdaki mevcut verilerin yerine geçer. Satın alımların etkilenmez; onları Premium ekranından geri yükleyebilirsin.", comment: "Backup restore footer"))
            }
        }
        .navigationTitle(String(localized: "backup_title", defaultValue: "Yedekle ve Geri Yükle", comment: "Backup screen title"))
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
        .alert(
            String(localized: "backup_confirm_title", defaultValue: "Yedek geri yüklensin mi?", comment: "Restore confirmation title"),
            isPresented: Binding(
                get: { pendingRestore != nil },
                set: { if !$0 { pendingRestore = nil } }
            ),
            presenting: pendingRestore
        ) { backup in
            Button(String(localized: "settings_cancel", defaultValue: "İptal", comment: "Cancel button"), role: .cancel) {}
            Button(String(localized: "backup_confirm_restore", defaultValue: "Geri Yükle", comment: "Confirm restore button"), role: .destructive) {
                BackupManager.shared.restoreAll(backup)
                HapticManager.shared.playNotification(type: .success)
                showRestoreDone = true
            }
        } message: { backup in
            Text(confirmationMessage(for: backup.summary))
        }
        .alert(
            String(localized: "backup_error_title", defaultValue: "Geri yüklenemedi", comment: "Restore error title"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(String(localized: "daily_zen_done", defaultValue: "Tamam", comment: "Done button"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(
            String(localized: "backup_done_title", defaultValue: "Geri yüklendi", comment: "Restore success title"),
            isPresented: $showRestoreDone
        ) {
            Button(String(localized: "daily_zen_done", defaultValue: "Tamam", comment: "Done button"), role: .cancel) {}
        } message: {
            Text(String(localized: "backup_done_message", defaultValue: "Verilerin yedekten geri yüklendi.", comment: "Restore success message"))
        }
    }

    // MARK: - Actions

    private func createBackup() {
        let backup = BackupManager.shared.makeBackup()
        do {
            backupURL = try BackupManager.shared.writeBackupFile(backup)
            backupSummary = backup.summary
            HapticManager.shared.playNotification(type: .success)
        } catch {
            errorMessage = String(localized: "backup_error_write", defaultValue: "Yedek dosyası oluşturulamadı.", comment: "Backup file could not be written")
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure:
            errorMessage = String(localized: "backup_error_read", defaultValue: "Dosya okunamadı.", comment: "File could not be read")
        case .success(let url):
            do {
                pendingRestore = try BackupManager.shared.readBackup(from: url)
            } catch ZenBackup.BackupError.newerVersion {
                errorMessage = String(localized: "backup_error_newer", defaultValue: "Bu yedek uygulamanın daha yeni bir sürümüyle oluşturulmuş. Önce uygulamayı güncelle.", comment: "Backup is from a newer app version")
            } catch ZenBackup.BackupError.corrupted {
                errorMessage = String(localized: "backup_error_corrupted", defaultValue: "Yedek dosyası bozuk görünüyor.", comment: "Backup file is corrupted")
            } catch {
                errorMessage = String(localized: "backup_error_invalid", defaultValue: "Bu dosya bir MyZenFlow yedeği değil.", comment: "File is not a backup")
            }
        }
    }

    private func confirmationMessage(for summary: ZenBackup.Summary) -> String {
        let date = summary.createdAt.formatted(date: .abbreviated, time: .omitted)
        return String(
            localized: "backup_confirm_message",
            defaultValue: "\(date) tarihli yedekte \(summary.sessionCount) seans ve \(summary.totalMinutes) dakika var. Bu cihazdaki mevcut verilerin yerine geçecek.",
            comment: "Restore confirmation message"
        )
    }
}
