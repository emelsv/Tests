using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApplication7
{
    class Program
    {
        static void Main(string[] args)
        {
            TestEventPublisher tep = new TestEventPublisher();
            tep.ValueChanged += Program_OnValueChanged;

            tep.Value = 0;
            tep.Value = 1;
            tep.Value = 2;

            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }

        static void Program_OnValueChanged(object sender, TestEventsArgs e)
        {
            Console.WriteLine("Old value = {0}, new value = {1}", e.OldValue, e.NewValue);
        }
    }


    public class TestEventsArgs : EventArgs
    {
        public int OldValue { get; set; }
        public int NewValue { get; set; }
    }

    public class TestEventPublisher
    {
        private int _value;

        public event EventHandler<TestEventsArgs> ValueChanged;

        public int Value
        {
            get
            {
                return _value;
            }
            set
            {
                if (_value != value)
                {
                    TestEventsArgs ea = new TestEventsArgs();
                    ea.OldValue = _value;
                    _value = value;
                    ea.NewValue = _value;
                    OnValueChanged(ea);
                }
            }
        }

        protected virtual void OnValueChanged(TestEventsArgs e)
        {
            ValueChanged?.Invoke(this, e);
        }
    }
}
