import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers.dart';
import '../providers.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  @override
  Widget build(BuildContext context) {
    final userRepo = ref.watch(userRepositoryProvider);
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Management')),
        body: const Center(child: Text('Administrator access is required.')),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () => _showAddUserSheet(context),
              label: const Text('Add User'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<AppUser>>(
        future: userRepo.list(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load company users.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const EmptyState(
                message: 'No users found', icon: Icons.group_off_outlined);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isAdmin = user.role == UserRole.admin;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showUserDetailModal(context, user),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isAdmin
                                ? AppTheme.primaryColor
                                : AppTheme.surfaceMuted,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                color: isAdmin
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 6),
                                    if (isAdmin)
                                      const Icon(Icons.verified,
                                          size: 14,
                                          color: AppTheme.primaryColor),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? AppTheme.primaryColor
                                      .withValues(alpha: 0.12)
                                  : AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isAdmin ? 'ADMIN' : 'STAFF',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isAdmin
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddUserSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    UserRole selectedRole = UserRole.staff;
    var isSaving = false;
    var obscurePassword = true;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Company User',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(labelText: 'Full name *'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter the user’s name.'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email *'),
                        validator: (value) => value == null ||
                                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(value.trim())
                            ? 'Enter a valid email address.'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Temporary password *',
                          helperText: 'Use at least 12 characters.',
                          suffixIcon: IconButton(
                            tooltip: obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setSheetState(
                                () => obscurePassword = !obscurePassword),
                            icon: Icon(obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (value) => value == null || value.length < 12
                            ? 'Password must be at least 12 characters.'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<UserRole>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role *'),
                        items: const [
                          DropdownMenuItem(
                              value: UserRole.staff, child: Text('Staff')),
                          DropdownMenuItem(
                              value: UserRole.admin, child: Text('Admin')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedRole = val);
                          }
                        },
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(errorMessage!,
                            style: const TextStyle(color: AppTheme.danger)),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() {
                                    isSaving = true;
                                    errorMessage = null;
                                  });
                                  try {
                                    await ref
                                        .read(userRepositoryProvider)
                                        .invite(
                                          name: nameController.text.trim(),
                                          email: emailController.text.trim(),
                                          password: passwordController.text,
                                          role: selectedRole,
                                          phone: '',
                                        );
                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                    if (mounted) {
                                      setState(() {});
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('User account created.')),
                                      );
                                    }
                                  } catch (error) {
                                    setSheetState(() {
                                      isSaving = false;
                                      errorMessage = _friendlyError(error);
                                    });
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.person_add_alt_1),
                          label: Text(isSaving ? 'Creating…' : 'Create user'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('User already registered') ||
        message.contains('already been registered')) {
      return 'An account with this email already exists.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  void _showUserDetailModal(BuildContext context, AppUser user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();
    var selectedRole = user.role;
    var isSaving = false;
    var obscurePassword = true;
    String? errorMessage;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit company user'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(labelText: 'Full name *'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter the user’s name.'
                              : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email *'),
                      validator: (value) => value == null ||
                              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(value.trim())
                          ? 'Enter a valid email address.'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'New password (optional)',
                        helperText: 'Leave blank to keep the current password.',
                        suffixIcon: IconButton(
                          tooltip: obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setDialogState(
                              () => obscurePassword = !obscurePassword),
                          icon: Icon(obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) =>
                          value != null && value.isNotEmpty && value.length < 12
                              ? 'Password must be at least 12 characters.'
                              : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role *'),
                      items: const [
                        DropdownMenuItem(
                            value: UserRole.staff, child: Text('Staff')),
                        DropdownMenuItem(
                            value: UserRole.admin, child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedRole = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Account status: ${user.status.name}'),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(errorMessage!,
                          style: const TextStyle(color: AppTheme.danger)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              onPressed: isSaving
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: ctx,
                        builder: (confirmContext) => AlertDialog(
                          title: const Text('Remove user?'),
                          content:
                              Text('Disable ${user.name}’s FleetPulse access?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(confirmContext, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.danger),
                              onPressed: () =>
                                  Navigator.pop(confirmContext, true),
                              child: const Text('Disable access'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !ctx.mounted) return;
                      setDialogState(() {
                        isSaving = true;
                        errorMessage = null;
                      });
                      try {
                        await ref.read(userRepositoryProvider).remove(user.id);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('User access disabled.')),
                          );
                        }
                      } catch (error) {
                        setDialogState(() {
                          isSaving = false;
                          errorMessage = _friendlyError(error);
                        });
                      }
                    },
              child: const Text('Remove'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSaving = true;
                        errorMessage = null;
                      });
                      try {
                        await ref.read(userRepositoryProvider).update(
                              user.copyWith(
                                name: nameController.text.trim(),
                                email: emailController.text.trim(),
                                role: selectedRole,
                              ),
                              password: passwordController.text.isEmpty
                                  ? null
                                  : passwordController.text,
                            );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('User details updated.')),
                          );
                        }
                      } catch (error) {
                        setDialogState(() {
                          isSaving = false;
                          errorMessage = _friendlyError(error);
                        });
                      }
                    },
              child: Text(isSaving ? 'Saving…' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
