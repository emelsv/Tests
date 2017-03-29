using System;
using System.Threading;
using System.Threading.Tasks;

namespace ConsoleApplication1
{
    class Program
    {
        public delegate void Swap(ref int x, ref int y);
        public static void Main(string[] args)
        {
            int a = 5;
            int b = 2;
            Swap sp = Swap1;
            sp += Swap2;

            sp?.Invoke(ref a, ref b);
            Foo(a, b);

            Counter c = new Counter();
            c.ValueChanged += CounterValueChanged;

            c.Value = 5;
            c.Value = 10;
            c.Value = -10;

            Console.ReadKey();
        }

        public static void CounterValueChanged(object sender, ValueChangedEventArgs e)
        {
            Console.WriteLine("Value changed. Old value = {0}, new value = {1}, difference = {2}", e.OldValue, e.NewValue, e.ValueDiff);
        }

        public static void Foo(int a, int b)
        {
            Console.WriteLine("a = {0} b = {1}", a, b);
        }

        public static void Swap1(ref int a, ref int b)
        {
            a = a ^ b;
            b = a ^ b;
            a = a ^ b;
        }

        public static void Swap2(ref int a, ref int b)
        {
            a += b;
            b = a - b;
            a = a - b;
        }
    }

    public class Counter
    {
        private static object _locker = new object();
        private int _value = 0;

        public event EventHandler<ValueChangedEventArgs> ValueChanged;
        public int Value
        {
            get
            {
                return this._value;
            }
            set
            {
                lock (_locker)
                {
                    if (this._value != value)
                    {
                        ValueChangedEventArgs args = new ValueChangedEventArgs();
                        args.OldValue = this._value;
                        this._value = value;
                        args.NewValue = this._value;
                        OnValueChanged(args);
                    }
                }
            }
        }

        protected virtual void OnValueChanged(ValueChangedEventArgs e)
        {
            ValueChanged?.Invoke(this, e);
        }
    }

    public class ValueChangedEventArgs : EventArgs
    {
        public int OldValue { get; set; }
        public int NewValue { get; set; }
        public int ValueDiff
        {
            get
            {
                return NewValue - OldValue;
            }
        }
    }

}
