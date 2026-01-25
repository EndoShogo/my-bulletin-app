//
//  GroupListView.swift
//  MyBulletinApp
//
//  グループチャット一覧画面
//

import SwiftUI
import Combine

struct GroupListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false
    
    var body: some View {
        List {
            ForEach(viewModel.groups) { group in
                NavigationLink(destination: ChatRoomView(chat: group)) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(group.name)
                                .font(.headline)
                            if let code = group.code {
                                Text("コード: \(code)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("グループチャット")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showCreateSheet = true }) {
                        Label("グループ作成", systemImage: "plus")
                    }
                    Button(action: { showJoinSheet = true }) {
                        Label("コードで参加", systemImage: "qrcode")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .onAppear {
            viewModel.fetchGroups()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateGroupSheet(viewModel: viewModel, isPresented: $showCreateSheet)
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinGroupSheet(viewModel: viewModel, isPresented: $showJoinSheet)
        }
        .alert("お知らせ", isPresented: $viewModel.showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }
}

struct CreateGroupSheet: View {
    @ObservedObject var viewModel: ChatListViewModel
    @Binding var isPresented: Bool
    @State private var groupName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("グループ名")) {
                    TextField("グループ名を入力", text: $groupName)
                }
            }
            .navigationTitle("グループ作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        viewModel.createGroup(name: groupName) { _ in
                            isPresented = false
                        }
                    }
                    .disabled(groupName.isEmpty)
                }
            }
        }
    }
}

struct JoinGroupSheet: View {
    @ObservedObject var viewModel: ChatListViewModel
    @Binding var isPresented: Bool
    @State private var code = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("参加コード")) {
                    TextField("10文字のコードを入力", text: $code)
                        .textInputAutocapitalization(.characters)
                }
            }
            .navigationTitle("コードで参加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("参加") {
                        viewModel.joinGroup(code: code) { _ in
                            isPresented = false
                        }
                    }
                    .disabled(code.count != 10)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        GroupListView()
    }
}
