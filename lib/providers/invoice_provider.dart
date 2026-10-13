import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice.dart';
import '../services/app_database.dart';
import '../services/database_service.dart';
import '../services/tax_engine.dart';
import 'database_provider.dart';
import 'expense_provider.dart';
import 'tax_rate_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Invoice list provider
// ═══════════════════════════════════════════════════════════════════════════════

/// Watches **all invoices** as a reactive stream (newest first).
///
/// UI usage — inside a [ConsumerWidget]:
/// ```dart
/// final invoicesAsync = ref.watch(invoiceListProvider);
/// invoicesAsync.when(
///   data: (invoices) => ...,
///   loading: () => const CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
final invoiceListProvider = StreamProvider<List<Invoice>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.watchAllInvoices();
});

// ═══════════════════════════════════════════════════════════════════════════════
// Filtered invoice providers
// ═══════════════════════════════════════════════════════════════════════════════

/// Returns only [InvoiceStatus.paid] invoices from the reactive stream.
final paidInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  return ref
      .watch(invoiceListProvider)
      .whenData(
        (invoices) =>
            invoices.where((inv) => inv.status == InvoiceStatus.paid).toList(),
      );
});

/// Returns only [InvoiceStatus.pending] invoices.
final pendingInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  return ref
      .watch(invoiceListProvider)
      .whenData(
        (invoices) => invoices
            .where((inv) => inv.status == InvoiceStatus.pending)
            .toList(),
      );
});

/// Returns only [InvoiceStatus.overdue] invoices.
final overdueInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  return ref
      .watch(invoiceListProvider)
      .whenData(
        (invoices) => invoices
            .where((inv) => inv.status == InvoiceStatus.overdue)
            .toList(),
      );
});

// ═══════════════════════════════════════════════════════════════════════════════
// Invoice CRUD notifier
// ═══════════════════════════════════════════════════════════════════════════════

/// Exposes async CRUD operations for invoices so the UI doesn't need to
/// hold a [DatabaseService] reference directly.
///
/// Usage:
/// ```dart
/// await ref.read(invoiceActionsProvider).deleteInvoice(id);
/// ```
final invoiceActionsProvider = Provider<InvoiceActions>((ref) {
  return InvoiceActions(ref.watch(databaseServiceProvider));
});

/// Helper class that wraps the [DatabaseService] invoice mutations.
/// Kept separate from the stream providers so mutations don't trigger
/// unnecessary rebuilds.
class InvoiceActions {
  const InvoiceActions(this._db);
  final DatabaseService _db;

  /// Generates next sequential document number format `PREFIX-YYYY-XXX`.
  Future<String> generateInvoiceNumber({String prefix = 'INV'}) =>
      _db.generateNextInvoiceNumber(prefix: prefix);

  /// Creates a new invoice or quote.
  Future<int> addInvoice(
    InvoicesCompanion entry,
    List<InvoiceItemsCompanion> items,
  ) => _db.insertInvoice(entry, items);

  Future<int> updateInvoice(InvoicesCompanion entry) =>
      _db.updateInvoice(entry);

  Future<int> updateInvoiceStatus(int invoiceId, InvoiceStatus status) =>
      _db.updateInvoiceStatus(invoiceId, status);

  Future<void> deleteInvoice(int id) => _db.deleteInvoice(id);

  Future<void> replaceItems(int invoiceId, List<InvoiceItemsCompanion> items) =>
      _db.replaceInvoiceItems(invoiceId, items);
}

// ═══════════════════════════════════════════════════════════════════════════════
// TaxEngine singleton provider
// ═══════════════════════════════════════════════════════════════════════════════

/// Provides the [TaxEngine] singleton. Stateless — never needs to be disposed.
final taxEngineProvider = Provider<TaxEngine>((ref) => const TaxEngine());

// ═══════════════════════════════════════════════════════════════════════════════
// Tax breakdown provider (derived / computed)
// ═══════════════════════════════════════════════════════════════════════════════

/// Derives a [TaxBreakdown] from the live invoice stream.
///
/// Automatically recomputes whenever new paid invoices arrive.
///
/// UI usage:
/// ```dart
/// final breakdownAsync = ref.watch(taxBreakdownProvider);
/// breakdownAsync.when(
///   data: (breakdown) => Text('Safe to spend: \${breakdown.safeToSpend}'),
///   loading: () => const CircularProgressIndicator(),
///   error: (e, _) => Text('$e'),
/// );
/// ```
final taxBreakdownProvider = Provider<AsyncValue<TaxBreakdown>>((ref) {
  final engine = ref.watch(taxEngineProvider);
  final invoicesAsync = ref.watch(invoiceListProvider);
  final expensesAsync = ref.watch(totalExpensesProvider);

  if (invoicesAsync is AsyncLoading || expensesAsync is AsyncLoading) {
    return const AsyncLoading();
  }

  if (invoicesAsync is AsyncError) {
    return AsyncError(invoicesAsync.error!, invoicesAsync.stackTrace!);
  }

  if (expensesAsync is AsyncError) {
    return AsyncError(expensesAsync.error!, expensesAsync.stackTrace!);
  }

  final invoices = invoicesAsync.value ?? [];
  final totalExpenses = expensesAsync.value ?? 0.0;

  final taxRatePercent = ref.watch(defaultTaxRateProvider);
  return AsyncData(
    engine.calculateEstimatedAvailable(
      invoices,
      totalExpenses,
      taxRatePercent: taxRatePercent,
    ),
  );
});
