import '@angular/compiler';
import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';
import { BirthdayService } from './birthday.service';
import { HttpClient } from '@angular/common/http';
import { AuthService } from './auth.service';
import { of } from 'rxjs';
import { Birthday, BirthdayCategory } from '../models/birthday.model';

// --- Mocks structure ---
const mockHttp = {
  get: vi.fn(),
  post: vi.fn(),
  put: vi.fn(),
  delete: vi.fn()
};

const mockAuthService = {
  isAuthenticated: vi.fn().mockReturnValue(true)
};

// Mocking @angular/core before importing BirthdayService isn't strictly necessary
// if we mock it globally or via Vitest's hoisting.
vi.mock('@angular/core', async (importOriginal) => {
  const original = await importOriginal<typeof import('@angular/core')>();
  return {
    ...original,
    inject: (token: any) => {
      if (token === HttpClient) {
        return mockHttp;
      }
      if (token === AuthService) {
        return mockAuthService;
      }
      return null;
    },
    effect: (cb: () => void) => {
      cb();
      return {
        destroy: () => {}
      };
    }
  };
});

describe('BirthdayService', () => {
  let service: BirthdayService;

  beforeEach(() => {
    vi.resetAllMocks();
    vi.useFakeTimers();
    // Fix system time to 2026-06-04 (June 4th, 2026)
    vi.setSystemTime(new Date('2026-06-04T12:00:00Z'));

    // Mock initial load GET request
    mockHttp.get.mockReturnValue(of([]));
    mockAuthService.isAuthenticated.mockReturnValue(true);

    service = new BirthdayService();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  // --- Core logic / helpers tests ---

  describe('getDaysUntil()', () => {
    it('should return 0 for a birthday today', () => {
      // 2026-06-04
      expect(service.getDaysUntil('1990-06-04')).toBe(0);
    });

    it('should return 1 for a birthday tomorrow', () => {
      // 2026-06-05
      expect(service.getDaysUntil('1990-06-05')).toBe(1);
    });

    it('should return 364 for a birthday yesterday (passed this year)', () => {
      // 2026-06-03 -> next is 2027-06-03 (364 days away from 2026-06-04)
      expect(service.getDaysUntil('1990-06-03')).toBe(364);
    });
  });

  describe('getCountdownLabel()', () => {
    it('should return __today__ when days is 0', () => {
      expect(service.getCountdownLabel(0)).toBe('__today__');
    });

    it('should return __tomorrow__ when days is 1', () => {
      expect(service.getCountdownLabel(1)).toBe('__tomorrow__');
    });

    it('should return custom pattern when days > 1', () => {
      expect(service.getCountdownLabel(10)).toBe('__days__:10');
    });
  });

  describe('getUrgencyClass()', () => {
    it('should return today for 0 days', () => {
      expect(service.getUrgencyClass(0)).toBe('today');
    });

    it('should return soon for 1-3 days', () => {
      expect(service.getUrgencyClass(1)).toBe('soon');
      expect(service.getUrgencyClass(3)).toBe('soon');
    });

    it('should return upcoming for 4-7 days', () => {
      expect(service.getUrgencyClass(4)).toBe('upcoming');
      expect(service.getUrgencyClass(7)).toBe('upcoming');
    });

    it('should return normal for > 7 days', () => {
      expect(service.getUrgencyClass(8)).toBe('normal');
    });
  });

  // --- Active Birthdays & Statistics ---

  describe('activeBirthdays & statistics', () => {
    it('should filter deleted birthdays and sort by days until next occurrence', () => {
      const sampleBirthdays: Birthday[] = [
        { id: 1, name: 'Alice', birthdate: '1990-06-05', category: 'FAMILY', isDeleted: false, reminderDays: 7 }, // Tomorrow (1 day)
        { id: 2, name: 'Bob', birthdate: '1992-06-04', category: 'FRIENDS', isDeleted: false, reminderDays: 7 },  // Today (0 days)
        { id: 3, name: 'Charlie', birthdate: '1995-06-03', category: 'WORK', isDeleted: true, reminderDays: 7 },  // Deleted
        { id: 4, name: 'David', birthdate: '1988-06-10', category: 'FAMILY', isDeleted: false, reminderDays: 7 }  // Next week (6 days)
      ];

      service.birthdays.set(sampleBirthdays);

      const active = service.activeBirthdays();
      expect(active).toHaveLength(3);
      // Sorted by days remaining: Bob (0), Alice (1), David (6)
      expect(active[0].name).toBe('Bob');
      expect(active[1].name).toBe('Alice');
      expect(active[2].name).toBe('David');
    });

    it('should calculate statistics correctly', () => {
      const sampleBirthdays: Birthday[] = [
        { id: 1, name: 'Alice', birthdate: '1990-06-04', category: 'FAMILY', isDeleted: false, reminderDays: 7 }, // Today (0 days)
        { id: 2, name: 'Bob', birthdate: '1992-06-14', category: 'FRIENDS', isDeleted: false, reminderDays: 7 },  // This month (June), 10 days away
        { id: 3, name: 'Charlie', birthdate: '1995-07-01', category: 'FAMILY', isDeleted: false, reminderDays: 7 }, // Next month (July), 27 days away
        { id: 4, name: 'David', birthdate: '1988-08-01', category: 'WORK', isDeleted: false, reminderDays: 7 }  // Later, > 30 days
      ];

      service.birthdays.set(sampleBirthdays);

      const stats = service.statistics();
      expect(stats.total).toBe(4);
      expect(stats.todayCount).toBe(1);      // Alice
      expect(stats.thisMonthCount).toBe(2);  // Alice (June 4), Bob (June 14)
      expect(stats.next30DaysCount).toBe(3); // Alice (0), Bob (10), Charlie (27)
      expect(stats.categoryDistribution).toEqual({
        FAMILY: 2,
        FRIENDS: 1,
        WORK: 1
      });
    });
  });

  // --- API Operations ---

  describe('API actions', () => {
    it('should load birthdays on storage reload', () => {
      const list: Birthday[] = [
        { id: 1, name: 'Alice', birthdate: '1990-06-04', category: 'FAMILY', isDeleted: false, reminderDays: 7 }
      ];
      mockHttp.get.mockReturnValue(of(list));

      service.loadFromStorage();

      expect(mockHttp.get).toHaveBeenCalledWith('http://localhost:8081/api/birthdays');
      expect(service.birthdays()).toEqual(list);
    });

    it('should add a birthday and append it to the signal list', () => {
      const newBirthday: Birthday = {
        id: 10,
        name: 'Eve',
        birthdate: '2000-12-25',
        category: 'FAMILY',
        isDeleted: false,
        reminderDays: 7,
        photoUrl: 'https://ui-avatars.com/api/?name=Eve&background=random&color=fff&rounded=true&bold=true'
      };
      mockHttp.post.mockReturnValue(of(newBirthday));

      service.birthdays.set([]);
      service.addBirthday('Eve', '2000-12-25', 'FAMILY');

      expect(mockHttp.post).toHaveBeenCalledWith('http://localhost:8081/api/birthdays', {
        name: 'Eve',
        birthdate: '2000-12-25',
        category: 'FAMILY',
        notes: undefined,
        reminderDays: 7,
        photoUrl: 'https://ui-avatars.com/api/?name=Eve&background=random&color=fff&rounded=true&bold=true'
      });
      expect(service.birthdays()).toContainEqual(newBirthday);
    });

    it('should update a birthday in the signal list', () => {
      const original: Birthday = { id: 5, name: 'Old Name', birthdate: '1990-01-01', category: 'FRIENDS', isDeleted: false, reminderDays: 7 };
      const updated: Birthday = { id: 5, name: 'New Name', birthdate: '1990-01-01', category: 'FRIENDS', isDeleted: false, reminderDays: 7 };
      mockHttp.put.mockReturnValue(of(updated));

      service.birthdays.set([original]);
      service.updateBirthday(5, 'New Name', '1990-01-01', 'FRIENDS');

      expect(mockHttp.put).toHaveBeenCalledWith('http://localhost:8081/api/birthdays/5', {
        name: 'New Name',
        birthdate: '1990-01-01',
        category: 'FRIENDS',
        notes: undefined,
        reminderDays: 7,
        photoUrl: undefined
      });
      expect(service.birthdays()).toContainEqual(updated);
      expect(service.birthdays()).not.toContainEqual(original);
    });

    it('should remove the birthday from the signal list on delete', () => {
      const b: Birthday = { id: 5, name: 'Name', birthdate: '1990-01-01', category: 'FRIENDS', isDeleted: false, reminderDays: 7 };
      mockHttp.delete.mockReturnValue(of({}));

      service.birthdays.set([b]);
      service.deleteBirthday(5);

      expect(mockHttp.delete).toHaveBeenCalledWith('http://localhost:8081/api/birthdays/5');
      expect(service.birthdays()).toHaveLength(0);
    });

    it('should trigger reminders and call the POST endpoint', () => {
      const response = { message: 'Processed', remindersProcessed: 2 };
      mockHttp.post.mockReturnValue(of(response));

      service.triggerReminders().subscribe(res => {
        expect(res).toEqual(response);
      });

      expect(mockHttp.post).toHaveBeenCalledWith('http://localhost:8081/api/birthdays/test-reminders', {});
    });
  });
});
