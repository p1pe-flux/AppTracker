import SwiftUI
import CoreData

struct TemplateListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: WorkoutTemplate.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutTemplate.createdAt, ascending: false)]
    ) private var templates: FetchedResults<WorkoutTemplate>
    
    @State private var showingCreateTemplate = false
    @State private var selectedTemplate: WorkoutTemplate?
    
    var body: some View {
        NavigationView {
            Group {
                if templates.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Templates",
                        message: "Create templates from your completed workouts",
                        actionTitle: "Browse Workouts",
                        action: {
                            dismiss()
                        }
                    )
                } else {
                    List {
                        ForEach(templates) { template in
                            TemplateRowView(template: template) {
                                createWorkoutFromTemplate(template)
                            }
                        }
                        .onDelete(perform: deleteTemplates)
                    }
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createWorkoutFromTemplate(_ template: WorkoutTemplate) {
        let duplicationService = WorkoutDuplicationService(context: context)
        
        Task {
            do {
                _ = try duplicationService.createWorkout(
                    from: template,
                    date: Date(),
                    name: template.wrappedName
                )
                HapticManager.shared.notification(.success)
                dismiss()
            } catch {
                print("Error creating workout from template: \(error)")
            }
        }
    }
    
    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            let template = templates[index]
            context.delete(template)
        }
        
        do {
            try context.save()
        } catch {
            print("Error deleting template: \(error)")
        }
    }
}

struct TemplateRowView: View {
    let template: WorkoutTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(template.wrappedName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Label("\(template.exercisesArray.count) exercises",
                          systemImage: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let createdAt = template.createdAt {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("Created \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let notes = template.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
