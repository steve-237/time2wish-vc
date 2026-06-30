import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { ContactService } from '../../services/contact.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-contacts',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="contacts-container">
      <header class="contacts-header">
        <h1>{{ t9n.t('contacts.title') || 'Mes Contacts' }}</h1>
        <button class="btn-secondary" (click)="router.navigate(['/dashboard/messaging'])">
          <span class="material-symbols-outlined">arrow_back</span>
          {{ t9n.t('contacts.back_to_messages') || 'Retour aux messages' }}
        </button>
      </header>

      @if (contactService.pendingRequests().length > 0) {
        <section class="pending-section glass-card">
          <h2>
            <span class="material-symbols-outlined">notifications</span>
            {{ t9n.t('contacts.pending') || 'Demandes en attente' }} ({{ contactService.pendingRequests().length }})
          </h2>
          <div class="requests-grid">
            @for (req of contactService.pendingRequests(); track req.id) {
              <div class="contact-card request-card">
                <img [src]="req.avatarUrl || 'assets/default-avatar.png'" alt="Avatar" class="avatar">
                <div class="info">
                  <h3>{{ req.fullName }}</h3>
                  <p>{{ req.email }}</p>
                </div>
                <div class="actions">
                  <button class="btn-PRO accept-btn" (click)="accept(req.id)">
                    <span class="material-symbols-outlined">check</span>
                  </button>
                  <button class="btn-secondary reject-btn" (click)="reject(req.id)">
                    <span class="material-symbols-outlined">close</span>
                  </button>
                </div>
              </div>
            }
          </div>
        </section>
      }

      <section class="search-section glass-card">
        <h2>
          <span class="material-symbols-outlined">person_search</span>
          {{ t9n.t('contacts.search_title') || 'Ajouter un contact' }}
        </h2>
        <div class="search-box">
          <input type="text" [ngModel]="searchQuery" (ngModelChange)="onSearchChange($event)" 
                 [placeholder]="t9n.t('contacts.search_placeholder') || 'Rechercher par nom ou email...'">
          <span class="material-symbols-outlined search-icon">search</span>
        </div>

        @if (contactService.searchResults().length > 0 && searchQuery.length > 2) {
          <div class="results-list">
            @for (user of contactService.searchResults(); track user.id) {
              <div class="result-item">
                <img [src]="user.avatarUrl || 'assets/default-avatar.png'" alt="Avatar" class="avatar">
                <div class="info">
                  <h3>{{ user.fullName }}</h3>
                  <p>{{ user.email }}</p>
                </div>
                <button class="btn-secondary" (click)="sendRequest(user.id)">
                  <span class="material-symbols-outlined">person_add</span>
                  {{ t9n.t('contacts.add') || 'Ajouter' }}
                </button>
              </div>
            }
          </div>
        }
      </section>

      <section class="my-contacts-section">
        <h2>
          <span class="material-symbols-outlined">group</span>
          {{ t9n.t('contacts.my_contacts') || 'Mes Contacts' }} ({{ contactService.contacts().length }})
        </h2>
        
        @if (contactService.contacts().length === 0) {
          <div class="empty-state glass-card">
            <span class="material-symbols-outlined empty-icon">group_off</span>
            <p>{{ t9n.t('contacts.empty') || 'Vous n\\'avez pas encore de contacts.' }}</p>
          </div>
        } @else {
          <div class="contacts-grid">
            @for (contact of contactService.contacts(); track contact.id) {
              <div class="contact-card glass-card">
                <img [src]="contact.avatarUrl || 'assets/default-avatar.png'" alt="Avatar" class="avatar">
                <div class="info">
                  <h3>{{ contact.fullName }}</h3>
                  <p>{{ contact.email }}</p>
                </div>
                <div class="actions">
                  <button class="btn-PRO" (click)="startChat(contact.userId)">
                    <span class="material-symbols-outlined">chat</span>
                    {{ t9n.t('contacts.message') || 'Message' }}
                  </button>
                  <button class="btn-icon" (click)="remove(contact.id)" title="Supprimer">
                    <span class="material-symbols-outlined text-danger">delete</span>
                  </button>
                </div>
              </div>
            }
          </div>
        }
      </section>
    </div>
  `,
  styleUrls: ['./contacts.scss']
})
export class ContactsPage implements OnInit {
  contactService = inject(ContactService);
  t9n = inject(TranslationService);
  toastService = inject(ToastService);
  router = inject(Router);

  searchQuery = '';
  searchTimeout: any;

  ngOnInit() {
    this.contactService.getContacts().subscribe();
    this.contactService.getPendingRequests().subscribe();
  }

  onSearchChange(query: string) {
    this.searchQuery = query;
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }
    
    if (query.trim().length > 2) {
      this.searchTimeout = setTimeout(() => {
        this.contactService.searchUsers(query.trim()).subscribe();
      }, 300);
    } else {
      this.contactService.searchResults.set([]);
    }
  }

  sendRequest(userId: number) {
    this.contactService.sendRequest(userId).subscribe({
      next: () => {
        this.toastService.success(this.t9n.t('contacts.request_sent') || 'Demande envoyée');
        this.searchQuery = '';
        this.contactService.searchResults.set([]);
      },
      error: () => this.toastService.error(this.t9n.t('error.generic') || 'Une erreur est survenue')
    });
  }

  accept(id: number) {
    this.contactService.acceptRequest(id).subscribe({
      next: () => this.toastService.success(this.t9n.t('contacts.accepted') || 'Contact ajouté'),
      error: () => this.toastService.error(this.t9n.t('error.generic') || 'Une erreur est survenue')
    });
  }

  reject(id: number) {
    this.contactService.rejectRequest(id).subscribe({
      next: () => this.toastService.success(this.t9n.t('contacts.rejected') || 'Demande refusée'),
      error: () => this.toastService.error(this.t9n.t('error.generic') || 'Une erreur est survenue')
    });
  }

  remove(id: number) {
    if (confirm(this.t9n.t('contacts.confirm_remove') || 'Voulez-vous vraiment supprimer ce contact ?')) {
      this.contactService.removeContact(id).subscribe({
        next: () => this.toastService.success(this.t9n.t('contacts.removed') || 'Contact supprimé'),
        error: () => this.toastService.error(this.t9n.t('error.generic') || 'Une erreur est survenue')
      });
    }
  }

  startChat(userId: number) {
    this.router.navigate(['/dashboard/messaging'], { queryParams: { startChatWith: userId } });
  }
}
