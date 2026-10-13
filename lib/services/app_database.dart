// GENERATED CODE — do not edit the annotation below.
// Run `flutter pub run build_runner build` to regenerate.
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/client.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

part 'app_database.g.dart';

/// The single Drift database for the app.
@DriftDatabase(
  tables: [Clients, InvoiceItems, Invoices, InvoiceItemLinks, Expenses],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Creates an isolated database with a caller-provided executor.
  ///
  /// This keeps widget tests off the app's persistent database while still
  /// exercising the real Drift queries and stream notifications.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(clients, clients.country);
          await m.addColumn(clients, clients.language);
          await m.addColumn(invoices, invoices.language);
        }
        if (from < 3) {
          await m.addColumn(invoices, invoices.template);
        }
        if (from < 4) {
          await m.addColumn(invoices, invoices.documentType);
        }
        if (from < 5) {
          await m.addColumn(invoices, invoices.paymentMethod);
        }
        if (from < 6) {
          await m.addColumn(invoices, invoices.notes);
        }
        if (from < 7) {
          await m.createTable(expenses);
        }
        if (from < 8) {
          await removeLegacyScreenshotData();
        }
      },
    );
  }

  /// Removes the fictional screenshot workspace created by app versions that
  /// predate schema version 8 while preserving every unrelated user record.
  Future<void> removeLegacyScreenshotData() async {
    const legacyClientTaxIds = {'US-DEMO-014', 'US-DEMO-027', 'US-DEMO-039'};

    final legacyClientIds =
        await (select(clients)
              ..where((client) => client.taxId.isIn(legacyClientTaxIds)))
            .map((client) => client.id)
            .get();

    if (legacyClientIds.isNotEmpty) {
      final legacyInvoiceIds =
          await (select(invoices)
                ..where((invoice) => invoice.clientId.isIn(legacyClientIds)))
              .map((invoice) => invoice.id)
              .get();

      if (legacyInvoiceIds.isNotEmpty) {
        final legacyItemIds =
            await (select(invoiceItemLinks)
                  ..where((link) => link.invoiceId.isIn(legacyInvoiceIds)))
                .map((link) => link.invoiceItemId)
                .get();

        await (delete(
          invoiceItemLinks,
        )..where((link) => link.invoiceId.isIn(legacyInvoiceIds))).go();
        if (legacyItemIds.isNotEmpty) {
          await (delete(
            invoiceItems,
          )..where((item) => item.id.isIn(legacyItemIds))).go();
        }
        await (delete(
          invoices,
        )..where((invoice) => invoice.id.isIn(legacyInvoiceIds))).go();
      }

      await (delete(
        clients,
      )..where((client) => client.id.isIn(legacyClientIds))).go();
    }

    const legacyExpenses = [
      ('Adobe Creative Cloud', 89.0, ExpenseCategory.software),
      ('Client meeting travel', 320.0, ExpenseCategory.travel),
      ('Coworking day passes', 145.0, ExpenseCategory.office),
      ('Client lunch', 62.5, ExpenseCategory.meals),
      ('Portfolio promotion', 48.0, ExpenseCategory.marketing),
    ];
    final existingExpenses = await select(expenses).get();
    final legacyExpenseIds = existingExpenses
        .where(
          (expense) => legacyExpenses.contains((
            expense.note,
            expense.amount,
            expense.category,
          )),
        )
        .map((expense) => expense.id)
        .toList();
    if (legacyExpenseIds.isNotEmpty) {
      await (delete(
        expenses,
      )..where((expense) => expense.id.isIn(legacyExpenseIds))).go();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static QueryExecutor _openConnection() {
    // drift_flutter picks the right SQLite backend per platform automatically.
    return driftDatabase(name: 'freelancer_db');
  }
}
