import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:freelancer/models/expense.dart';
import 'package:freelancer/services/app_database.dart';
import 'package:freelancer/services/database_service.dart';

void main() {
  late AppDatabase database;
  late DatabaseService databaseService;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    databaseService = DatabaseService.forTesting(database);
  });

  tearDown(() => databaseService.close());

  test('legacy screenshot cleanup preserves unrelated user records', () async {
    final userClientId = await databaseService.insertClient(
      ClientsCompanion.insert(name: 'Real customer'),
    );
    final legacyClientId = await databaseService.insertClient(
      ClientsCompanion.insert(
        name: 'Northstar Creative Co.',
        taxId: const Value('US-DEMO-014'),
      ),
    );

    await databaseService.insertInvoice(
      InvoicesCompanion.insert(
        invoiceNumber: 'INV-2026-001',
        date: DateTime(2026, 8, 22),
        clientId: userClientId,
        totalAmount: const Value(399),
      ),
      [
        InvoiceItemsCompanion.insert(
          description: 'Real service',
          unitPrice: 399,
        ),
      ],
    );
    await databaseService.insertInvoice(
      InvoicesCompanion.insert(
        invoiceNumber: 'INV-2026-014',
        date: DateTime(2026, 7, 22),
        clientId: legacyClientId,
        totalAmount: const Value(2420),
      ),
      [
        InvoiceItemsCompanion.insert(
          description: 'Brand strategy workshop',
          unitPrice: 1200,
        ),
      ],
    );

    await databaseService.insertExpense(
      ExpensesCompanion.insert(
        amount: const Value(89),
        category: const Value(ExpenseCategory.software),
        date: DateTime(2026, 7, 24),
        note: const Value('Adobe Creative Cloud'),
      ),
    );
    await databaseService.insertExpense(
      ExpensesCompanion.insert(
        amount: const Value(120),
        category: const Value(ExpenseCategory.software),
        date: DateTime(2026, 8, 22),
        note: const Value('Adobe Creative Cloud'),
      ),
    );

    await database.removeLegacyScreenshotData();

    expect(
      (await databaseService.getAllClients()).map((client) => client.name),
      ['Real customer'],
    );
    expect(
      (await databaseService.getAllInvoices()).map(
        (invoice) => invoice.invoiceNumber,
      ),
      ['INV-2026-001'],
    );
    expect(await databaseService.getAllInvoiceItems(), hasLength(1));
    expect(
      (await databaseService.getAllExpenses()).map((expense) => expense.amount),
      [120],
    );
  });
}
