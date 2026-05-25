import { Skeleton } from '@/components/ui';

function SkelBar({ className }: { className: string }): JSX.Element {
    return <Skeleton variant="rect" className={className} />;
}

export function SkeletonState(): JSX.Element {
    return (
        <div className="space-y-10" data-testid="market-skeleton">
            <div className="h-[52px] w-full rounded-full bg-fs-nav/85 fs-skeleton" />

            <div className="flex flex-col gap-8 md:flex-row md:items-end md:justify-between">
                <div className="space-y-4">
                    <SkelBar className="h-[10px] w-[120px] rounded-md" />
                    <SkelBar className="h-[92px] w-[min(520px,70vw)] rounded-md" />
                    <SkelBar className="h-[14px] w-[min(420px,70vw)] rounded-md" />
                </div>
                <div className="grid grid-cols-2 gap-4 md:grid-cols-4 md:gap-8">
                    {Array.from({ length: 4 }).map((_, index) => (
                        <div key={index} className="space-y-2">
                            <SkelBar className="h-[10px] w-[80px] rounded-md" />
                            <SkelBar className="h-[28px] w-[72px] rounded-md" />
                        </div>
                    ))}
                </div>
            </div>

            <div className="flex flex-col overflow-hidden rounded-[20px] border border-fs-border bg-fs-surface md:flex-row">
                <div className="flex-1 space-y-5 p-8">
                    <div className="flex items-center justify-between gap-3">
                        <SkelBar className="h-[10px] w-[120px] rounded-md" />
                        <SkelBar className="h-[22px] w-[120px] rounded-full" />
                    </div>
                    <SkelBar className="h-[44px] w-[60%] rounded-md" />
                    <SkelBar className="h-[12px] w-[40%] rounded-md" />
                    <SkelBar className="h-[12px] w-[90%] rounded-md" />
                    <div className="pt-6">
                        <SkelBar className="h-[84px] w-[220px] rounded-md" />
                    </div>
                </div>
                <div className="space-y-3 border-t border-fs-border bg-[rgb(251_252_252)] p-7 md:w-[44%] md:max-w-[480px] md:border-l md:border-t-0">
                    {Array.from({ length: 3 }).map((_, index) => (
                        <div key={index} className="space-y-2 rounded-[12px] border border-fs-border bg-fs-surface px-3.5 py-3">
                            <div className="flex items-center justify-between gap-3">
                                <SkelBar className="h-[14px] w-[120px] rounded-md" />
                                <SkelBar className="h-[14px] w-[48px] rounded-md" />
                            </div>
                            <SkelBar className="h-[2px] w-full rounded-full" />
                        </div>
                    ))}
                </div>
            </div>

            <div className="grid grid-cols-1 gap-5 xl:grid-cols-3">
                {Array.from({ length: 6 }).map((_, index) => (
                    <div key={index} className="space-y-4 rounded-[18px] border border-fs-border bg-fs-surface p-5">
                        <div className="flex items-center justify-between gap-3">
                            <SkelBar className="h-[10px] w-[110px] rounded-md" />
                            <SkelBar className="h-[24px] w-[24px] rounded-full" />
                        </div>
                        <SkelBar className="h-[22px] w-[65%] rounded-md" />
                        <SkelBar className="h-[11px] w-[80%] rounded-md" />
                        <SkelBar className="h-[34px] w-[40%] rounded-md" />
                        <div className="space-y-2 pt-2">
                            <SkelBar className="h-[12px] w-full rounded-md" />
                            <SkelBar className="h-[12px] w-full rounded-md" />
                            <SkelBar className="h-[12px] w-full rounded-md" />
                        </div>
                        <SkelBar className="h-[2px] w-full rounded-full" />
                    </div>
                ))}
            </div>
        </div>
    );
}
