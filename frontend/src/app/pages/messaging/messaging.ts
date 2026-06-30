import { Component, inject, OnInit, OnDestroy, signal, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { MessagingService, ConversationDto, ConversationMemberDto } from '../../services/messaging.service';
import { ContactService } from '../../services/contact.service';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-messaging',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="messaging-layout">
      <!-- LEFT SIDEBAR -->
      <aside class="sidebar" [class.mobile-hidden]="activeConversation()">
        <header class="sidebar-header">
          <h1>{{ t9n.t('messaging.title') || 'Messagerie' }}</h1>
          <div class="header-actions">
            <button class="btn-icon" (click)="router.navigate(['/dashboard/contacts'])" [title]="t9n.t('messaging.contacts') || 'Contacts'">
              <span class="material-symbols-outlined">person_add</span>
            </button>
            <button class="btn-icon primary" (click)="isNewConversationModalOpen = true" [title]="t9n.t('messaging.new') || 'Nouveau message'">
              <span class="material-symbols-outlined">edit_square</span>
            </button>
          </div>
        </header>

        <div class="search-bar">
          <span class="material-symbols-outlined">search</span>
          <input type="text" [(ngModel)]="searchQuery" [placeholder]="t9n.t('messaging.search') || 'Rechercher une conversation...'">
        </div>

        <div class="conversations-list">
          @if (filteredConversations().length === 0) {
            <div class="empty-list">
              <span class="material-symbols-outlined">chat_bubble_outline</span>
              <p>{{ t9n.t('messaging.no_conversations') || 'Aucune conversation' }}</p>
            </div>
          } @else {
            @for (conv of filteredConversations(); track conv.id) {
              <div class="conversation-item" 
                   [class.active]="activeConversation()?.id === conv.id"
                   (click)="selectConversation(conv)">
                <div class="avatar-wrapper">
                  @if (conv.type === 'GROUP') {
                    <div class="group-avatar">
                      <span class="material-symbols-outlined">group</span>
                    </div>
                  } @else {
                    <img [src]="getOtherMember(conv)?.avatarUrl || 'assets/default-avatar.png'" alt="Avatar" class="avatar">
                  }
                  @if (conv.unreadCount > 0) {
                    <span class="unread-badge">{{ conv.unreadCount }}</span>
                  }
                </div>
                <div class="conv-info">
                  <div class="conv-header">
                    <h3>{{ conv.name }}</h3>
                    @if (conv.lastMessageAt) {
                      <span class="time">{{ conv.lastMessageAt | date:'shortTime' }}</span>
                    }
                  </div>
                  <div class="conv-last-msg">
                    <p>{{ conv.lastMessage || '...' }}</p>
                  </div>
                </div>
              </div>
            }
          }
        </div>
      </aside>

      <!-- RIGHT PANEL (CHAT) -->
      <main class="chat-panel" [class.mobile-hidden]="!activeConversation()">
        @if (!activeConversation()) {
          <div class="no-chat-selected">
            <div class="icon-wrapper">
              <span class="material-symbols-outlined">forum</span>
            </div>
            <h2>{{ t9n.t('messaging.select_to_start') || 'Sélectionnez une conversation' }}</h2>
            <p>{{ t9n.t('messaging.select_desc') || 'Choisissez un contact à gauche pour commencer à discuter.' }}</p>
            <button class="btn-PRO mt-4" (click)="isNewConversationModalOpen = true">
              {{ t9n.t('messaging.start_new') || 'Démarrer une nouvelle discussion' }}
            </button>
          </div>
        } @else {
          <header class="chat-header">
            <button class="btn-icon back-btn" (click)="backToSidebar()">
              <span class="material-symbols-outlined">arrow_back</span>
            </button>
            <div class="chat-title" (click)="toggleGroupInfo()">
              <div class="avatar-wrapper">
                @if (activeConversation()!.type === 'GROUP') {
                  <div class="group-avatar small">
                    <span class="material-symbols-outlined">group</span>
                  </div>
                } @else {
                  <img [src]="getOtherMember(activeConversation()!)?.avatarUrl || 'assets/default-avatar.png'" alt="Avatar" class="avatar small">
                }
              </div>
              <div class="title-info">
                <h2>{{ activeConversation()!.name }}</h2>
                @if (activeConversation()!.type === 'GROUP') {
                  <span class="members-count">{{ activeConversation()!.members.length }} membres</span>
                }
              </div>
            </div>
            <div class="header-actions">
              <button class="btn-icon" (click)="toggleGroupInfo()">
                <span class="material-symbols-outlined">info</span>
              </button>
            </div>
          </header>

          <div class="messages-area" #scrollMe>
            @for (msg of messagingService.activeMessages(); track msg.id) {
              <div class="message-wrapper" [class.mine]="msg.senderId === currentUserId()">
                @if (msg.senderId !== currentUserId() && activeConversation()!.type === 'GROUP') {
                  <img [src]="msg.senderAvatar || 'assets/default-avatar.png'" class="msg-avatar" [title]="msg.senderName">
                }
                <div class="message-bubble">
                  @if (msg.senderId !== currentUserId() && activeConversation()!.type === 'GROUP') {
                    <span class="sender-name">{{ msg.senderName }}</span>
                  }
                  <div class="content">{{ msg.content }}</div>
                  <span class="msg-time">{{ msg.createdAt | date:'shortTime' }}</span>
                </div>
              </div>
            }
          </div>

          <footer class="chat-input-area">
            <input type="text" [(ngModel)]="newMessageContent" (keyup.enter)="sendMessage()" 
                   [placeholder]="t9n.t('messaging.type_message') || 'Écrire un message...'">
            <button class="btn-send" (click)="sendMessage()" [disabled]="!newMessageContent.trim()">
              <span class="material-symbols-outlined">send</span>
            </button>
          </footer>
        }
      </main>

      <!-- GROUP INFO PANEL -->
      @if (isGroupInfoOpen && activeConversation()) {
        <aside class="group-info-panel">
          <header>
            <h2>{{ t9n.t('messaging.info') || 'Infos' }}</h2>
            <button class="btn-icon" (click)="isGroupInfoOpen = false">
              <span class="material-symbols-outlined">close</span>
            </button>
          </header>
          
          <div class="info-content">
            <div class="group-hero">
              @if (activeConversation()!.type === 'GROUP') {
                <div class="group-avatar large">
                  <span class="material-symbols-outlined">group</span>
                </div>
              } @else {
                <img [src]="getOtherMember(activeConversation()!)?.avatarUrl || 'assets/default-avatar.png'" alt="Avatar" class="avatar large">
              }
              <h3>{{ activeConversation()!.name }}</h3>
              <p>{{ activeConversation()!.type === 'GROUP' ? 'Groupe' : 'Contact privé' }}</p>
            </div>

            <div class="members-list">
              <h4>{{ t9n.t('messaging.members') || 'Membres' }} ({{ activeConversation()!.members.length }})</h4>
              
              @if (isAdmin() && activeConversation()!.type === 'GROUP') {
                <button class="btn-secondary add-member-btn" (click)="isAddMemberModalOpen = true">
                  <span class="material-symbols-outlined">person_add</span>
                  {{ t9n.t('messaging.add_member') || 'Ajouter un membre' }}
                </button>
              }

              @for (member of activeConversation()!.members; track member.userId) {
                <div class="member-item">
                  <img [src]="member.avatarUrl || 'assets/default-avatar.png'" alt="Avatar" class="avatar small">
                  <div class="member-info">
                    <span class="name">{{ member.fullName }} {{ member.userId === currentUserId() ? '(Vous)' : '' }}</span>
                    <span class="role">{{ member.role === 'ADMIN' ? 'Administrateur' : 'Membre' }}</span>
                  </div>
                  @if (isAdmin() && member.userId !== currentUserId()) {
                    <button class="btn-icon danger" (click)="removeMember(member.userId)">
                      <span class="material-symbols-outlined">person_remove</span>
                    </button>
                  }
                </div>
              }
            </div>
          </div>
        </aside>
      }
    </div>

    <!-- NEW CONVERSATION MODAL -->
    @if (isNewConversationModalOpen) {
      <div class="modal-backdrop" (click)="isNewConversationModalOpen = false">
        <div class="modal-content" (click)="$event.stopPropagation()">
          <header class="modal-header">
            <h2>{{ t9n.t('messaging.new_conversation') || 'Nouvelle discussion' }}</h2>
            <button class="btn-icon" (click)="isNewConversationModalOpen = false">
              <span class="material-symbols-outlined">close</span>
            </button>
          </header>
          
          <div class="modal-body">
            <div class="tabs">
              <button [class.active]="!isCreatingGroup" (click)="isCreatingGroup = false">Privé</button>
              <button [class.active]="isCreatingGroup" (click)="isCreatingGroup = true">Groupe</button>
            </div>

            @if (isCreatingGroup) {
              <div class="form-group">
                <label>Nom du groupe</label>
                <input type="text" [(ngModel)]="newGroupName" placeholder="Entrez un nom pour le groupe">
              </div>
            }

            <div class="contacts-selection">
              <h4>Sélectionnez des contacts</h4>
              @for (contact of contactService.contacts(); track contact.userId) {
                <label class="contact-checkbox">
                  <input type="checkbox" 
                         [checked]="selectedContactIds.includes(contact.userId)"
                         (change)="toggleContactSelection(contact.userId)"
                         [type]="isCreatingGroup ? 'checkbox' : 'radio'"
                         [name]="'contact'">
                  <img [src]="contact.avatarUrl || 'assets/default-avatar.png'" class="avatar small">
                  <span>{{ contact.fullName }}</span>
                </label>
              }
              @if (contactService.contacts().length === 0) {
                <p class="text-muted">Vous n'avez pas encore de contacts. <a routerLink="/dashboard/contacts">Ajouter des contacts</a>.</p>
              }
            </div>
          </div>
          
          <footer class="modal-footer">
            <button class="btn-secondary" (click)="isNewConversationModalOpen = false">Annuler</button>
            <button class="btn-PRO" (click)="createConversation()" [disabled]="selectedContactIds.length === 0 || (isCreatingGroup && !newGroupName.trim())">
              Créer
            </button>
          </footer>
        </div>
      </div>
    }

    <!-- ADD MEMBER MODAL -->
    @if (isAddMemberModalOpen) {
      <div class="modal-backdrop" (click)="isAddMemberModalOpen = false">
        <div class="modal-content" (click)="$event.stopPropagation()">
          <header class="modal-header">
            <h2>{{ t9n.t('messaging.add_member') || 'Ajouter un membre' }}</h2>
            <button class="btn-icon" (click)="isAddMemberModalOpen = false">
              <span class="material-symbols-outlined">close</span>
            </button>
          </header>
          
          <div class="modal-body">
            <div class="contacts-selection">
              @for (contact of getAvailableContactsToAdd(); track contact.userId) {
                <div class="contact-add-item">
                  <img [src]="contact.avatarUrl || 'assets/default-avatar.png'" class="avatar small">
                  <span>{{ contact.fullName }}</span>
                  <button class="btn-secondary" (click)="addMember(contact.userId)">Ajouter</button>
                </div>
              }
              @if (getAvailableContactsToAdd().length === 0) {
                <p class="text-muted">Aucun contact disponible à ajouter.</p>
              }
            </div>
          </div>
        </div>
      </div>
    }
  `,
  styleUrls: ['./messaging.scss']
})
export class MessagingPage implements OnInit, OnDestroy {
  messagingService = inject(MessagingService);
  contactService = inject(ContactService);
  authService = inject(AuthService);
  t9n = inject(TranslationService);
  toastService = inject(ToastService);
  router = inject(Router);
  route = inject(ActivatedRoute);

  searchQuery = '';
  newMessageContent = '';
  
  isGroupInfoOpen = false;
  isNewConversationModalOpen = false;
  isAddMemberModalOpen = false;
  
  isCreatingGroup = false;
  newGroupName = '';
  selectedContactIds: number[] = [];

  currentUserId = signal<number>(-1);

  constructor() {
    effect(() => {
      const user = this.authService.currentUser();
      if (user) this.currentUserId.set(user.id);
    });
  }

  ngOnInit() {
    const token = this.authService.accessToken();
    if (token) {
      this.messagingService.connect(token);
    }

    this.contactService.getContacts().subscribe();
    this.messagingService.loadConversations().subscribe(() => {
      // Check query params for startChatWith
      this.route.queryParams.subscribe(params => {
        if (params['startChatWith']) {
          const userId = Number(params['startChatWith']);
          const existingConv = this.messagingService.conversations().find(c => 
            c.type === 'PRIVATE' && c.members.some(m => m.userId === userId)
          );
          
          if (existingConv) {
            this.selectConversation(existingConv);
          } else {
            // Need to create it
            this.messagingService.createPrivateConversation(userId).subscribe(conv => {
              this.selectConversation(conv);
            });
          }
          // Remove query param
          this.router.navigate([], { queryParams: { startChatWith: null }, queryParamsHandling: 'merge' });
        }
      });
    });

    setInterval(() => this.scrollToBottom(), 500);
  }

  ngOnDestroy() {
    this.messagingService.disconnect();
    this.messagingService.activeConversationId.set(null);
  }

  activeConversation() {
    const id = this.messagingService.activeConversationId();
    if (!id) return null;
    return this.messagingService.conversations().find(c => c.id === id) || null;
  }

  filteredConversations() {
    const query = this.searchQuery.toLowerCase().trim();
    if (!query) return this.messagingService.conversations();
    
    return this.messagingService.conversations().filter(c => {
      if (c.name?.toLowerCase().includes(query)) return true;
      if (c.type === 'PRIVATE') {
        const other = this.getOtherMember(c);
        if (other?.fullName.toLowerCase().includes(query)) return true;
      }
      return false;
    });
  }

  getOtherMember(conv: ConversationDto): ConversationMemberDto | null {
    return conv.members.find(m => m.userId !== this.currentUserId()) || null;
  }

  selectConversation(conv: ConversationDto) {
    this.messagingService.activeConversationId.set(conv.id);
    this.messagingService.subscribeToConversation(conv.id);
    this.messagingService.loadMessages(conv.id).subscribe(() => this.scrollToBottom());
    this.isGroupInfoOpen = false;
  }

  backToSidebar() {
    this.messagingService.activeConversationId.set(null);
    this.isGroupInfoOpen = false;
  }

  sendMessage() {
    const conv = this.activeConversation();
    if (!conv || !this.newMessageContent.trim()) return;
    
    this.messagingService.sendMessage(conv.id, this.newMessageContent.trim());
    this.newMessageContent = '';
  }

  scrollToBottom() {
    const el = document.querySelector('.messages-area');
    if (el) {
      el.scrollTop = el.scrollHeight;
    }
  }

  toggleGroupInfo() {
    this.isGroupInfoOpen = !this.isGroupInfoOpen;
  }

  isAdmin(): boolean {
    const conv = this.activeConversation();
    if (!conv) return false;
    const me = conv.members.find(m => m.userId === this.currentUserId());
    return me?.role === 'ADMIN';
  }

  toggleContactSelection(userId: number) {
    if (!this.isCreatingGroup) {
      this.selectedContactIds = [userId];
    } else {
      const idx = this.selectedContactIds.indexOf(userId);
      if (idx === -1) {
        this.selectedContactIds.push(userId);
      } else {
        this.selectedContactIds.splice(idx, 1);
      }
    }
  }

  createConversation() {
    if (this.isCreatingGroup) {
      if (!this.newGroupName.trim() || this.selectedContactIds.length === 0) return;
      
      const user = this.authService.currentUser();
      if (user?.plan === 'BASIC') {
        this.toastService.error("L'abonnement Basic ne permet pas de créer des groupes.");
        return;
      }
      if (user?.plan === 'PLUS' && this.selectedContactIds.length > 4) {
        this.toastService.error("L'abonnement Plus permet d'ajouter maximum 4 membres à un groupe.");
        return;
      }

      this.messagingService.createGroupConversation(this.newGroupName.trim(), this.selectedContactIds).subscribe({
        next: (conv) => {
          this.isNewConversationModalOpen = false;
          this.resetNewConvForm();
          this.selectConversation(conv);
        },
        error: (err) => this.toastService.error(err.error?.message || 'Erreur')
      });
    } else {
      if (this.selectedContactIds.length === 0) return;
      this.messagingService.createPrivateConversation(this.selectedContactIds[0]).subscribe({
        next: (conv) => {
          this.isNewConversationModalOpen = false;
          this.resetNewConvForm();
          this.selectConversation(conv);
        },
        error: (err) => this.toastService.error(err.error?.message || 'Erreur')
      });
    }
  }

  resetNewConvForm() {
    this.isCreatingGroup = false;
    this.newGroupName = '';
    this.selectedContactIds = [];
  }

  getAvailableContactsToAdd() {
    const conv = this.activeConversation();
    if (!conv) return [];
    const memberIds = conv.members.map(m => m.userId);
    return this.contactService.contacts().filter(c => !memberIds.includes(c.userId));
  }

  addMember(userId: number) {
    const conv = this.activeConversation();
    if (!conv) return;
    this.messagingService.addMember(conv.id, userId).subscribe({
      next: () => {
        this.isAddMemberModalOpen = false;
        this.toastService.success('Membre ajouté');
        this.messagingService.loadConversations().subscribe(() => {
          const updated = this.messagingService.conversations().find(c => c.id === conv.id);
          if (updated) {
            // update local active object if needed, though signals should handle it
          }
        });
      },
      error: (err) => this.toastService.error(err.error?.message || 'Erreur')
    });
  }

  removeMember(userId: number) {
    const conv = this.activeConversation();
    if (!conv) return;
    if (confirm('Voulez-vous vraiment retirer ce membre ?')) {
      this.messagingService.removeMember(conv.id, userId).subscribe({
        next: () => {
          this.toastService.success('Membre retiré');
          this.messagingService.loadConversations().subscribe();
        },
        error: (err) => this.toastService.error('Erreur')
      });
    }
  }
}
